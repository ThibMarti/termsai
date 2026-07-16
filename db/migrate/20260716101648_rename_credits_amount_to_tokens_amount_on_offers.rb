class RenameCreditsAmountToTokensAmountOnOffers < ActiveRecord::Migration[8.1]
  def change
    rename_column :offers, :credits_amount, :tokens_amount
  end
end
