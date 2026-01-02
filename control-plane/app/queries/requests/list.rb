# frozen_string_literal: true

module Requests
  class List
    def self.call(org:, user:, state: "all")
      new(org, user, state).call
    end

    def initialize(org, user, state)
      @org   = org
      @user  = user
      @state = state
    end

    def call
      results = []

      results += approval_requests if approvals?
      results += direct_grants     if grants?

      results.sort_by { |r| r[:requested_at] || r[:expires_at] }.reverse
    end

    private

    attr_reader :org, :user, :state

    def approvals?
      state.in?(%w[pending approved denied all])
    end

    def grants?
      state.in?(%w[granted all])
    end

    def approval_requests
      PolicyApproval
        .where(organization: org, requester: user)
        .yield_self { |q| state == "all" ? q : q.where(state: state) }
        .order(created_at: :desc)
        .map do |a|
        {
          id: "req_#{a.id}",
          type: "approval",
          state: a.state,
          dataset: a.dataset,
          fields: a.fields,
          requested_at: a.created_at,
          approved_at: a.approved_at,
          grant_ref: a.grant&.ref
        }
      end
    end

    def direct_grants
      Grant
        .where(organization: org, user: user)
        .active
        .order(created_at: :desc)
        .map do |g|
        {
          id: g.ref,
          type: "grant",
          state: "granted",
          dataset: g.dataset,
          fields: g.fields,
          expires_at: g.expires_at
        }
      end
    end
  end
end
