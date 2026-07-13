class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.integer :credits_amount
      t.integer :price_cents
      t.string :name

      t.timestamps
    end
  end
end
