class Token < ApplicationRecord
  belongs_to :user

  # Ensure that balance is always present and is a positive number or zero
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
