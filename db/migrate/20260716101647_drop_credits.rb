class DropCredits < ActiveRecord::Migration[8.1]
  def change
    drop_table :credits do |t|
      t.bigint "user_id", null: false
      t.integer "credits_amount"
      t.timestamps
    end
  end
end
