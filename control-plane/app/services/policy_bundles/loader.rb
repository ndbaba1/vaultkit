module PolicyBundles
  class Loader
    class BundleNotFound < StandardError; end

    def self.active_for!(org:)
      row = PolicyBundleVersion.active_for(org.id).first
      raise BundleNotFound, "No active policy bundle for org=#{org.slug}" if row.nil?

      {
        version: row.bundle_version,
        checksum: row.checksum,
        registry: row.bundle_json.fetch("registry"),
        policies: row.bundle_json.fetch("policies"),
        meta: row.bundle_json.fetch("bundle")
      }
    end
  end
end
