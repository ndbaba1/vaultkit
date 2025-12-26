class DataSource < ApplicationRecord
  include MultiTenant

  MODES = %w[secret_provider local_encrypted].freeze
  PROVIDERS = %w[aws gcp azure vault mock].freeze
  ENGINES = %w[postgres mysql snowflake bigquery redshift mssql].freeze

  encrypts :config_encrypted
  encrypts :local_credentials_encrypted

  validates :name, :engine, :mode, :org_id, :created_by, presence: true
  validates :engine, inclusion: { in: ENGINES }
  validates :mode, inclusion: { in: MODES }
  validates :provider, inclusion: { in: PROVIDERS }, if: -> { mode == "secret_provider" }

  validate :config_shape

  def config=(hash)  = self.config_encrypted = hash.to_json
  def config         = JSON.parse(config_encrypted || "{}")

  def local_credentials=(hash) = self.local_credentials_encrypted = hash.to_json
  def local_credentials        = JSON.parse(local_credentials_encrypted || "{}")

  private

  def config_shape
    if mode == "secret_provider"
      cfg = config
      errors.add(:config, "secret_ref required") unless cfg["secret_ref"].present?
      # Optional per provider:
      if provider == "aws" && cfg["role_arn"].present? && cfg["external_id"].blank?
        errors.add(:config, "external_id required with role_arn")
      end
    elsif mode == "local_encrypted"
      creds = local_credentials
      %w[host port database username password].each do |k|
        errors.add(:local_credentials, "#{k} required") unless creds[k].present?
      end
    end
  end
end
