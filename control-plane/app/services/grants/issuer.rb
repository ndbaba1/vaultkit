# frozen_string_literal: true

module Grants
  class Issuer
    def issue!(actor:, request:, decision:, policy_id:, reason:, ttl_seconds:)
      expires_at = Time.current + ttl_seconds
      id         = "grant_" + SecureRandom.hex(8)

      jwt_issuer = Rails.application.config.jwt_issuer

      token = jwt_issuer.issue_grant_token(
        user: actor,
        grant_id: id,
        expires_at: expires_at
      )

      Grant.create!(
        organization: actor.organization,
        user: actor,
        dataset: request[:dataset],
        fields: request[:fields],
        mask_fields: request[:mask_fields] || [],
        aql: request[:aql],
        decision: decision,
        policy_id: policy_id,
        reason: reason,
        ttl_seconds: ttl_seconds,
        expires_at: expires_at,
        session_token: token
      )
    end
  end
end
