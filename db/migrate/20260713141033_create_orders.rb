class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :offer, null: false, foreign_key: true
      t.integer :amount_cents
      t.string :state
      t.string :checkout_session_id

      t.timestamps
    end
  end
end
