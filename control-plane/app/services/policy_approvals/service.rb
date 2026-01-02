# frozen_string_literal: true

module PolicyApprovals
  class Service
    PENDING  = "pending".freeze
    APPROVED = "approved".freeze
    DENIED   = "denied".freeze

    def enqueue!(org:, requester:, dataset:, fields:, aql:, approver_role:, reason:)
      fingerprint = Aql::Fingerprint.call(aql)

      existing =
        PolicyApproval.find_by(
          organization: org,
          requester: requester,
          aql_fingerprint: fingerprint,
          state: PENDING
        )

      return existing if existing

      PolicyApproval.create!(
        organization: org,
        requester: requester,
        dataset: dataset,
        fields: extract_fields(aql),
        aql: aql,
        aql_fingerprint: fingerprint,
        approver_role: approver_role,
        reason: reason,
        state: PENDING
      )
    rescue ActiveRecord::RecordNotUnique
      PolicyApproval.find_by!(
        organization: org,
        requester: requester,
        aql_fingerprint: fingerprint,
        state: PENDING
      )
    end

    def approve!(approval:, approver:, ttl_seconds:)
      raise "Already processed" unless approval.state == PENDING

      grant =
        Grants::Issuer.new.issue!(
          actor: approval.requester,
          request: {
            dataset: approval.dataset,
            fields: approval.fields,
            mask_fields: [],
            aql: approval.aql
          },
          decision: PolicyExecution::PolicyActions::ALLOW,
          policy_id: "approval_flow",
          reason: "Approved by #{approver.email}",
          ttl_seconds: ttl_seconds
        )

      approval.update!(
        state: APPROVED,
        approver: approver,
        approved_at: Time.current,
        grant: grant
      )

      grant
    end

    def deny!(approval:, approver:, reason:)
      raise "Already processed" unless approval.state == PENDING

      approval.update!(
        state: DENIED,
        approver: approver,
        approved_at: Time.current,
        reason: reason
      )
    end

    private

    def extract_fields(aql)
      cols = Array(aql["columns"])
      aggs = Array(aql["aggregates"]).map { |a| a["field"] }
      (cols + aggs).compact.map { |f| f.to_s.split(".", 2).last }.uniq.sort
    end
  end
end
