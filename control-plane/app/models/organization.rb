class Organization < ApplicationRecord
  has_many :users
  has_many :data_sources

  validates :name, presence: true
end
