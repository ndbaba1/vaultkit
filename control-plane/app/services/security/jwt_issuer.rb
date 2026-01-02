# frozen_string_literal: true

module Security
  class JwtIssuer
    def initialize(private_key:)
      @private_key = private_key
    end

    def issue_grant_token(user:, grant_id:, expires_at:)
      payload = {
        iss: "vaultkit-control-plane",
        sub: user,
        type: "grant",
        grant_id: grant_id,
        exp: expires_at.to_i
      }

      encode(payload)
    end

    def issue_internal_token(role:, datasource:, expires_at:)
      payload = {
        iss: "vaultkit-control-plane",
        sub: "vaultkit-internal",
        type: "internal",
        role: role,
        datasource: datasource,
        exp: expires_at.to_i
      }

      encode(payload)
    end

    private

    def encode(payload)
      JWT.encode(payload, @private_key, "RS256")
    end
  end
end
