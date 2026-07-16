class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :tokens, dependent: :destroy
  has_many :user_scans, dependent: :destroy
  has_many :scans, through: :user_scans

  after_create :grant_free_token

  def can_scan?
    tokens.sum(:token_amount).positive?
  end

  def total_scan_allowance
    tokens.sum(:token_amount)
  end

  def consume_scan_allowance!
    token = tokens.where("token_amount > 0").first
    token.decrement!(:token_amount)
    token.destroy if token.token_amount.zero?
  end

  private

  def grant_free_token
    tokens.create!(token_amount: 1)
  end
end
