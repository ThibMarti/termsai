class Order < ApplicationRecord
    belongs_to :user
    belongs_to :offer

    validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :state, presence: true
end
