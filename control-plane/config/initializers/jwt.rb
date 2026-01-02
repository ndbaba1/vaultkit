# frozen_string_literal: true

require Rails.root.join("app/services/security/jwt_issuer")
require Rails.root.join("app/services/security/key_loader")

Rails.application.config.jwt_issuer =
  Security::JwtIssuer.new(
    private_key: Security::KeyLoader.private_key
  )