class AddBalanceToTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :tokens, :balance, :integer, default: 1, null: false
  end
end
