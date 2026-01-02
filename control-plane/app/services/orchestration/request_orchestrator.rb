# frozen_string_literal: true

module Orchestration
  class RequestOrchestrator
    include PolicyExecution::PolicyActions

    def initialize(
      policy_engine:,
      registry:,
      grant_finder:,
      grant_issuer:,
      approval_service:,
      funl_client:,
      audit_logger:
    )
      @policy_engine    = policy_engine
      @registry         = registry
      @grant_finder     = grant_finder
      @grant_issuer     = grant_issuer
      @approval_service = approval_service
      @funl_client      = funl_client
      @audit_logger     = audit_logger
    end

    # Entry point
    def execute(aql:, actor:, options: {})
      raise ArgumentError, "AQL must be provided" if aql.nil?

      dataset = extract_dataset!(aql)
      fields  = extract_fields(aql)
      masked_fields = []

      canonical_aql =
        Aql::Canonicalizer.call(
          aql: aql,
          allowed_fields: fields,
          masked_fields: masked_fields
        )

      request_ctx =
        build_request_context(
          dataset: dataset,
          fields: fields,
          actor: actor,
          options: options
        ).merge(
          aql: canonical_aql
        )

      audit("request.received", actor, actor.organization, request_ctx)

      # 1) Grant reuse
      if (grant = find_reusable_grant(request_ctx, actor))
        return execute_with_existing_grant(
          grant,
          actor
        )
      end

      # 2) Policy evaluation
      decision = evaluate_policy(request_ctx, actor, dataset, fields)

      # 3) Act on decision
      dispatch_decision(
        decision: decision,
        request_ctx: request_ctx,
        dataset: dataset,
        fields: fields,
        actor: actor,
        aql: aql
      )
    end

    # Policy evaluation
    def evaluate_policy(request_ctx, actor, dataset, fields)
      decision = @policy_engine.evaluate(request_ctx)

      unless PolicyExecution::PolicyActions.valid?(decision[:action])
        raise ArgumentError, "Invalid policy action: #{decision[:action].inspect}"
      end

      audit(
        "policy.evaluated",
        actor,
        actor.organization,
        decision.merge(dataset: dataset, fields: fields)
      )

      decision
    end

    # Decision dispatch
    def dispatch_decision(decision:, request_ctx:, dataset:, fields:, actor:, aql:)
      case decision[:action]

      when DENY
        deny_request(decision, actor, dataset, fields)

      when REQUIRE_APPROVAL
        queue_for_approval(decision, actor, dataset, fields, aql)

      when ALLOW, MASK
        grant_and_execute(
          decision: decision,
          request_ctx: request_ctx,
          dataset: dataset,
          fields: fields,
          actor: actor,
          aql: aql
        )

      else
        raise ArgumentError, "Unknown policy action: #{decision[:action]}"
      end
    end

    # DENY
    def deny_request(decision, actor, dataset, fields)
      audit(
        "request.denied",
        actor,
        actor.organization,
        decision.merge(dataset: dataset, fields: fields)
      )

      {
        status: :denied,
        policy_id: decision[:policy_id],
        reason: decision[:reason]
      }
    end

    # REQUIRE APPROVAL
    def queue_for_approval(decision, actor, dataset, fields, aql)
      approval =
        @approval_service.enqueue!(
          org: actor.organization,
          requester: actor,
          dataset: dataset,
          fields: fields,
          approver_role: decision[:approver_role],
          reason: decision[:reason],
          aql: aql
        )

      audit(
        "request.queued_for_approval",
        actor,
        actor.organization,
        {
          approval_id: approval.id,
          dataset: dataset,
          fields: fields
        }
      )

      {
        status: :queued,
        request_id: approval.id,
        approver_role: decision[:approver_role],
        reason: decision[:reason]
      }
    end

    # GRANT REUSE
    def find_reusable_grant(request_ctx, actor)
      @grant_finder.find_valid(
        org: actor.organization,
        user: actor,
        request: request_ctx
      )
    end

    def execute_with_existing_grant(grant, actor)
      audit(
        "grant.reused",
        actor,
        actor.organization,
        {
          grant_ref: grant.ref,
          dataset: grant.dataset,
          expires_at: grant.expires_at
        }
      )

      rows =
        @funl_client.execute(
          aql: grant.aql,
          bearer: grant.session_token
        )

      {
        status: :ok,
        reused: true,
        grant_ref: grant.ref,
        expires_at: grant.expires_at,
        meta: rows["meta"],
        rows: rows["rows"]
      }
    end

    # GRANT ISSUE
    def grant_and_execute(decision:, request_ctx:, dataset:, fields:, actor:, aql:)
      ttl = decision[:ttl] || 3600

      masked_fields = resolve_masking(decision, dataset, fields)

      canonical_aql =
        Aql::Canonicalizer.call(
          aql: aql,
          allowed_fields: fields,
          masked_fields: masked_fields
        )

      grant =
        @grant_issuer.issue!(
          actor: actor,
          request: request_ctx.merge(
            mask_fields: masked_fields,
            aql: canonical_aql
          ),
          decision: decision[:action],
          policy_id: decision[:policy_id],
          reason: decision[:reason],
          ttl_seconds: ttl
        )

      audit(
        "grant.issued",
        actor,
        actor.organization,
        {
          grant_ref: grant.ref,
          dataset: dataset,
          fields: fields,
          masked_fields: masked_fields,
          expires_at: grant.expires_at,
          ttl: ttl
        }
      )

      {
        status: :granted,
        grant_ref: grant.ref,
        expires_at: grant.expires_at,
        masked_fields: masked_fields
      }
    end

    # Helpers
    def resolve_masking(decision, dataset, fields)
      return [] unless decision[:action] == MASK

      Masking.resolve_masks(
        dataset: dataset,
        requested_fields: fields,
        registry: @registry,
        decision: decision
      )
    end

    def build_request_context(dataset:, fields:, actor:, options:)
      {
        dataset: dataset,
        fields: fields,
        requester: actor.email,
        requester_role: actor.role,
        requester_clearance: actor.respond_to?(:clearance) ? actor.clearance : nil,
        requester_region: options[:requester_region],
        dataset_region: options[:dataset_region],
        environment: options[:environment] || "production",
        time: Time.current
      }
    end

    def extract_dataset!(aql)
      dataset = aql["source_table"] || aql["dataset"]
      raise ArgumentError, "AQL missing source_table" if dataset.blank?
      dataset.to_s
    end

    def extract_fields(aql)
      cols = Array(aql["columns"]).map { |c| strip(c) }
      aggs = Array(aql["aggregates"]).map { |a| strip(a["field"]) if a["field"] }
      (cols + aggs).compact.uniq
    end

    def strip(value)
      value.to_s.split(".", 2).last
    end

    def audit(event, actor, organization, details)
      @audit_logger.log(
        event: event,
        actor: actor,
        organization: organization,
        details: details
      )
    end
  end
end
