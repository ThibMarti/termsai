class CreateUserScans < ActiveRecord::Migration[8.1]
  def change
    create_table :user_scans do |t|
      t.references :user, null: false, foreign_key: true
      t.references :scan, null: false, foreign_key: true

      t.timestamps
    end
  end
end
