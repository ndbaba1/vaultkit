require 'rails_helper'

RSpec.describe "MultiTenant enforcement" do
  it "ensures all models with organization_id include MultiTenant" do
    # Load all application models
    Rails.application.eager_load!

    tenant_models = ApplicationRecord.descendants.select do |m|
      m.table_exists? && m.column_names.include?("organization_id")
    rescue StandardError
      false
    end

    expect(tenant_models).not_to be_empty, "No tenant models found — check migrations?"

    tenant_models.each do |model|
      expect(model.included_modules).to include(MultiTenant),
        "#{model.name} defines organization_id but does NOT include MultiTenant"
    end
  end
end
