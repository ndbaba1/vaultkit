class PolicyBundleVersion < ApplicationRecord
  include MultiTenant

  belongs_to :organization
  belongs_to :created_by, class_name: "User", optional: true

  STATES = %w[uploaded active superseded revoked].freeze
  validates :state, inclusion: { in: STATES }

  scope :active, -> { where(state: "active") }
end
