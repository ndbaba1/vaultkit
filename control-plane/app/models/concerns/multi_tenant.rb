module MultiTenant
  extend ActiveSupport::Concern

  included do
    belongs_to :organization

    default_scope -> {
      if Current.organization.present?
        where(organization_id: Current.organization.id)
      else
        all
      end
    }
  end
end
