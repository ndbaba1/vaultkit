# frozen_string_literal: true

class SchemaRegistryEntry < ApplicationRecord
  belongs_to :organization

  validates :dataset_name, presence: true
  validates :datasource_name, presence: true
  validates :source, presence: true, inclusion: { in: %w[bundle scan manual] }

  validates :dataset_name, uniqueness: { scope: :organization_id }

  def fields_by_name
    fields.index_by { _1["name"] || _1[:name] }
  end
end
