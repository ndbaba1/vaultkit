# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :organization
  belongs_to :actor, class_name: "User", optional: true

  validates :event, presence: true
  validates :occurred_at, presence: true
end
