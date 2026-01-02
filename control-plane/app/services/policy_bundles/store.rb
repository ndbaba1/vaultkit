module PolicyBundles
  class Store
    def self.store!(org:, actor:, bundle:, activate: false)
      meta = bundle.fetch("bundle")
      version = meta.fetch("bundle_version")
      checksum = meta.fetch("checksum")

      record = PolicyBundleVersion.create!(
        organization: org,
        created_by: actor,
        bundle_version: version,
        checksum: checksum,
        bundle_json: bundle,
        state: "uploaded",
        source_repo: meta.dig("source", "repo"),
        source_ref: meta.dig("source", "ref"),
        source_commit_sha: meta.dig("source", "commit_sha")
      )

      PolicyBundles::Activator.activate!(org: org, version: record, actor: actor) if activate
      record
    end
  end
end
