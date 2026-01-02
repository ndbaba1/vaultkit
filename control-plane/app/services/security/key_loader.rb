# frozen_string_literal: true

module Security
  class KeyLoader
    def self.private_key
      path = ENV.fetch("VKIT_PRIVATE_KEY")
      raise "Private key not found: #{path}" unless File.exist?(path)

      OpenSSL::PKey::RSA.new(File.read(path))
    end
  end
end
