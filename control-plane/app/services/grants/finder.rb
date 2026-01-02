# frozen_string_literal: true

module Grants
  class Finder
    def find_valid(org:, user:, request:)
      canonical_aql =
        Aql::Canonicalizer.call(
          aql: request[:aql],
          allowed_fields: request[:fields],
          masked_fields: request[:mask_fields] || []
        )

      fingerprint = Aql::Fingerprint.call(canonical_aql)

      Grant
        .where(
          organization: org,
          user: user,
          fingerprint: fingerprint
        )
        .where("expires_at > ?", Time.current)
        .order(expires_at: :desc)
        .first
    end
  end
end
