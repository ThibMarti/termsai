class CreateScanResults < ActiveRecord::Migration[8.1]
  def change
    create_table :scan_results do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :score
      t.string :verdict
      t.text :description

      t.timestamps
    end
  end
end
