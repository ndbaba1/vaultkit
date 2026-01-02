# frozen_string_literal: true

# frozen_string_literal: true

module Encryption
  class Encryptor
    def initialize(key:)
      @key = [key].pack("H*")
    end

    def encrypt(plaintext)
      cipher = OpenSSL::Cipher::AES256.new(:gcm)
      cipher.encrypt
      cipher.key = @key

      iv = SecureRandom.random_bytes(12)
      cipher.iv = iv

      ciphertext = cipher.update(plaintext.to_s) + cipher.final
      tag = cipher.auth_tag

      Base64.strict_encode64(iv + tag + ciphertext)
    end

    def decrypt(encoded)
      raw = Base64.strict_decode64(encoded)

      iv         = raw[0, 12]
      tag        = raw[12, 16]
      ciphertext = raw[28..]

      cipher = OpenSSL::Cipher::AES256.new(:gcm)
      cipher.decrypt
      cipher.key = @key
      cipher.iv  = iv
      cipher.auth_tag = tag

      cipher.update(ciphertext) + cipher.final
    end
  end
end
