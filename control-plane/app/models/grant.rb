# app/models/grant.rb
class Grant < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  has_one :policy_approval

  validates :dataset, :decision, :ttl_seconds, :expires_at, :session_token, :aql, presence: true
  validates :ref, uniqueness: true

  before_validation :ensure_ref, :ensure_fingerprint, on: :create

  scope :active, -> { where("expires_at > ?", Time.current) }

  def active?
    expires_at > Time.current
  end

  REF_PREFIX = "g".freeze

  private

  def ensure_ref
    return if ref.present?

    self.ref = generate_ref
  end

  def ensure_fingerprint
    self.fingerprint ||= Aql::Fingerprint.call(aql)
  end

  def generate_ref
    base = dataset.to_s.parameterize(separator: "_")
    loop do
      candidate = "#{REF_PREFIX}_#{base}_#{SecureRandom.hex(2)}"
      break candidate unless Grant.exists?(ref: candidate)
    end
  end
end
