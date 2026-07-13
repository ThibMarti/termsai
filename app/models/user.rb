class User < ApplicationRecord
  has_many :scans, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_one :credit, dependent: :destroy
  has_one :token, dependent: :destroy

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable
end
