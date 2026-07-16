class Offer < ApplicationRecord
  has_many :orders

  validates :name, presence: true
  validates :tokens_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
