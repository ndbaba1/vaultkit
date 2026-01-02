# frozen_string_literal: true
class ScanRun < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  validates :datasource_name, presence: true
  validates :status, inclusion: { in: %w[queued completed failed] }
end
