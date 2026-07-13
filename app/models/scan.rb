class Scan < ApplicationRecord
    has_many :user_scans, dependent: :destroy
    has_many :users, through: :user_scans

  validates :url, presence: true, uniqueness: true
end
