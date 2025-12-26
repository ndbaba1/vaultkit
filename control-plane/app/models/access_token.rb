class AccessToken < ApplicationRecord
  belongs_to :organization
  has_secure_token :raw_token

  before_create :hash_token

  def hash_token
    self.plaintext_token = SecureRandom.hex(32) # e.g. sk_live_abc123
    self.token_digest = BCrypt::Password.create(plaintext_token)
  end

  def self.verify(raw_token)
    find_each do |record|
      return record if BCrypt::Password.new(record.token_digest) == raw_token && record.active?
    end
    nil
  end
end
