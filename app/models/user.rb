class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  class User < ApplicationRecord
      has_many :user_scans, dependent: :destroy
      has_many :scans, through: :user_scans
      has_many :credits, dependent: :destroy
      has_many :tokens, dependent: :destroy
      has_many :orders, dependent: :destroy
  end
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
