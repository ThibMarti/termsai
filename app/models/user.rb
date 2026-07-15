class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :token, dependent: :destroy
  has_many :user_scans, dependent: :destroy
  has_many :scans, through: :user_scans

  after_create :grant_free_token

  def can_scan?
    token.present? && token.balance.positive?
  end

  def consume_scan_allowance!
    return false unless can_scan?

    token.decrement!(:balance, 1)
  end

  private

  def grant_free_token
    Token.create!(user: self)
  end
end
