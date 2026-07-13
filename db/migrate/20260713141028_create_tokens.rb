class CreateTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :token_amount
      t.timestamps
    end
  end
end
