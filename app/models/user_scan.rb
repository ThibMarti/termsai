class UserScan < ApplicationRecord
    belongs_to :user
    belongs_to :scan
end
