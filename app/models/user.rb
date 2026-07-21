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

  # Bearer credential for the Chrome extension — separate from Devise's
  # session auth, since the extension has no session cookie to reuse.
  def regenerate_extension_token!
    update!(extension_token: SecureRandom.hex(20))
  end

  def extension_token
    regenerate_extension_token! if self[:extension_token].blank?
    self[:extension_token]
  end

  private

  def grant_free_token
    tokens.create!(token_amount: 1)
  end
end
