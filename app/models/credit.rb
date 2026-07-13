class Credit < ApplicationRecord
    belongs_to :user

    validates :credits_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
