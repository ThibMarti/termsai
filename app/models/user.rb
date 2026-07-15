class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :tokens, dependent: :destroy
  has_one  :credit, dependent: :destroy
  has_many :user_scans, dependent: :destroy
  has_many :scans, through: :user_scans

  after_create :grant_free_token

  def can_scan?
    tokens.sum(:token_amount).positive? || credit&.credits_amount.to_i.positive?
  end

  def consume_scan_allowance!
    token = tokens.where("token_amount > 0").first
    if token
      token.decrement!(:token_amount)
      token.destroy if token.token_amount.zero?
    else
      credit.decrement!(:credits_amount)
    end
  end

  private

  def grant_free_token
    tokens.create!(token_amount: 1)
  end
end
