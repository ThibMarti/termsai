class CreateCredits < ActiveRecord::Migration[8.1]
  def change
    create_table :credits do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :credits_amount

      t.timestamps
    end
  end
end
