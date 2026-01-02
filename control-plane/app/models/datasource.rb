# frozen_string_literal: true

class Datasource < ApplicationRecord
  belongs_to :organization

  # Virtual attributes (do NOT use attr_accessor)
  attr_reader :username, :password

  validates :name, presence: true,
                   uniqueness: { scope: :organization_id }
  validates :engine, presence: true

  before_validation :encrypt_credentials,
                    if: -> { @username.present? || @password.present? }

  def username=(value)
    @username = value
  end

  def password=(value)
    @password = value
  end

  def username
    decrypt(username_encrypted)
  end

  def password
    decrypt(password_encrypted)
  end

  def credentials
    {
      "username" => username,
      "password" => password
    }
  end
  
  def connection_config
    config.slice("host", "port", "database").merge(credentials).merge(
      "name" => name,
      "engine" => engine
    )
  end

  private

  def encrypt_credentials
    enc = encryptor

    self.username_encrypted = enc.encrypt(@username) if @username.present?
    self.password_encrypted = enc.encrypt(@password) if @password.present?
  end

  def encryptor
    Encryption::Encryptor.new(
      key: Rails.application.credentials.dig(:vaultkit, :encryption_key)
    )
  end

  def decrypt(value)
    return nil if value.blank?

    encryptor.decrypt(value)
  end
end
