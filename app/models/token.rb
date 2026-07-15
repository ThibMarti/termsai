class Token < ApplicationRecord
  belongs_to :user

    validates :token_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
