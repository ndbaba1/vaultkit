class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  belongs_to :organization
  has_many :data_sources, foreign_key: :created_by

  validates :email, presence: true, uniqueness: true

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

end
