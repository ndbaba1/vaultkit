# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :users
  has_many :datasources
  has_many :policy_bundle_versions

  has_one :active_policy_bundle_version,
          -> { where(state: "active") },
          class_name: "PolicyBundleVersion"

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  # Slugs should be stable once created
  attr_readonly :slug

  def active_policy_bundle
    active_policy_bundle_version&.bundle_json
  end

  def active_policy_bundle!
    active_policy_bundle || raise("No active policy bundle for org=#{slug}")
  end

  private

  def generate_slug
    return if slug.present?

    base = name
      .to_s
      .downcase
      .strip
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/\A-|-+\z/, "")

    self.slug = ensure_unique_slug(base)
  end

  def ensure_unique_slug(base)
    slug = base
    counter = 2

    while self.class.exists?(slug: slug)
      slug = "#{base}-#{counter}"
      counter += 1
    end

    slug
  end
end
