# frozen_string_literal: true

module PolicyBundles
  class Activator
    def self.activate!(org:, version:, actor:)
      raise ActivateError, "Bundle must belong to org" unless version.organization_id == org.id
      raise ActivateError, "Cannot activate revoked bundle" if version.state == "revoked"

      PolicyBundleVersion.transaction do
        PolicyBundleVersion
          .where(organization_id: org.id, state: "active")
          .lock(true)
          .each { |active| active.update!(state: "superseded") unless active.id == version.id }

        version.update!(state: "active", activated_at: Time.current)
      end

      # TODO: Emit an audit event here
      # Audit::Logger.emit(event: "policy_bundle.activated", actor: actor, payload: {...})

      PolicyBundles::RegistrySeeder.seed!(
        org: org,
        bundle_version: version,
        actor: actor
      )

      true
    end
  end
end

