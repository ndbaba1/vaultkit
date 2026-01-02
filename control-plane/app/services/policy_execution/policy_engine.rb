# frozen_string_literal: true

module PolicyExecution
  class PolicyEngine
    include PolicyActions

    DEFAULT_TTL = 3600

    # Higher number = stronger decision
    ACTION_PRIORITY = {
      DENY             => 3,
      REQUIRE_APPROVAL => 2,
      MASK             => 1,
      ALLOW            => 0
    }.freeze

    def initialize(policies:, registry:)
      @policies    = Array(policies)
      @registry    = registry
      @field_index = build_field_index(registry)
    end

    # Public API
    def evaluate(request)
      decisions = @policies.filter_map do |policy|
        evaluate_policy(policy, request)
      end

      pick_highest_priority(decisions) || allow_decision
    end

    private

    # Policy evaluation
    def evaluate_policy(policy, request)
      return unless policy_matches?(policy, request)

      action = policy.fetch("action", ALLOW).to_s

      unless PolicyActions.valid?(action)
        raise ArgumentError, "Invalid policy action: #{action.inspect}"
      end

      ttl = parse_ttl(policy)

      case action
      when DENY
        decision(DENY, policy, ttl)

      when REQUIRE_APPROVAL
        decision(
          REQUIRE_APPROVAL,
          policy,
          ttl,
          approver_role: policy.dig("approval", "approver_role")
        )

      when MASK
        decision(
          MASK,
          policy,
          ttl,
          masking: policy["masking"]
        )

      when ALLOW
        decision(ALLOW, policy, ttl)
      end
    end

    def decision(action, policy, ttl, extra = {})
      {
        action: action,
        policy_id: policy["id"],
        reason: policy["reason"],
        ttl: ttl
      }.merge(extra)
    end

    def allow_decision
      {
        action: ALLOW,
        ttl: DEFAULT_TTL
      }
    end

    def pick_highest_priority(decisions)
      decisions.max_by { |d| ACTION_PRIORITY.fetch(d[:action]) }
    end

    # Matching logic
    def policy_matches?(policy, request)
      match = policy["match"] || {}

      dataset_match?(match, request) &&
        fields_match?(match, request) &&
        context_match?(match, request) &&
        when_match?(policy["when"], request)
    end

    def dataset_match?(match, request)
      expected = match["dataset"]
      return true if expected.nil?

      expected.to_s == request[:dataset].to_s
    end

    def fields_match?(match, request)
      rules = match["fields"]
      return true unless rules.is_a?(Hash)

      dataset   = request[:dataset].to_s
      requested = Array(request[:fields]).map(&:to_s)
      metadata  = @field_index[dataset] || {}

      tags =
        requested.flat_map { |f| Array(metadata.dig(f, "tags")) }

      sensitivities =
        requested.map { |f| metadata.dig(f, "sensitivity") }.compact

      return false if rules["category"]    && !tags.include?(rules["category"].to_s)
      return false if rules["sensitivity"] && !sensitivities.include?(rules["sensitivity"].to_s)
      return false if rules["contains"]    && (Array(rules["contains"]).map(&:to_s) - tags).any?
      return false if rules["any"]         && (requested & Array(rules["any"]).map(&:to_s)).empty?
      return false if rules["all"]         && (Array(rules["all"]).map(&:to_s) - requested).any?

      true
    end

    def context_match?(match, request)
      ctx = match["context"]
      return true unless ctx.is_a?(Hash)

      ctx.each do |key, expected|
        next if key.to_s == "time"
        actual = request[key.to_sym]
        return false if expected && actual.to_s != expected.to_s
      end

      if (time_rule = ctx["time"])
        return false unless Vkit::Core::TimeWindow.matches?(time_rule, request[:time])
      end

      true
    end

    def when_match?(when_clause, request)
      return true unless when_clause.is_a?(Hash)

      when_clause.all? do |key, expected|
        request[key.to_sym].to_s == expected.to_s
      end
    end

    # Registry & TTL helpers
    def build_field_index(registry)
      index = Hash.new { |h, k| h[k] = {} }

      Array(registry["datasets"]).each do |dataset|
        dataset_name = dataset["name"].to_s

        Array(dataset["fields"]).each do |field|
          index[dataset_name][field["name"].to_s] = field
        end
      end

      index
    end

    def parse_ttl(policy)
      raw = policy["ttl_seconds"]
      Vkit::Core::TtlParser.parse(raw) || DEFAULT_TTL
    end
  end
end
