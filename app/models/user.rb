class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :tokens, dependent: :destroy
  has_one  :credit, dependent: :destroy
  has_many :user_scans, dependent: :destroy
  has_many :scans, through: :user_scans

  after_create :grant_free_token

  def can_scan?
    tokens.exists? || credit&.credits_amount.to_i.positive?
  end

  def consume_scan_allowance!
    return tokens.first.destroy if tokens.exists?

    credit.decrement!(:credits_amount)
  end

  private

  def grant_free_token
    tokens.create!(token_amount: 1)
  end
end
