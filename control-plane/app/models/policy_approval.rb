# frozen_string_literal: true

class PolicyApproval < ApplicationRecord
  belongs_to :organization
  belongs_to :requester, class_name: "User"
  belongs_to :approver,  class_name: "User", optional: true
  belongs_to :grant, optional: true

  STATES = %w[pending approved denied].freeze

  validates :state, inclusion: { in: STATES }
  validates :dataset, presence: true
  validates :aql, presence: true
  validates :aql_fingerprint, presence: true

  before_validation :canonicalize_aql, on: :create
  before_validation :ensure_fingerprint, on: :create

  private

  def canonicalize_aql
    return if aql.blank?

    self.aql =
      Aql::Canonicalizer.call(
        aql: aql,
        allowed_fields: fields,
        masked_fields: []
      )
  end

  def ensure_fingerprint
    return if aql.blank?
    return if aql_fingerprint.present?

    self.aql_fingerprint = Aql::Fingerprint.call(aql)
  end
end
