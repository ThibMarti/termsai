class CreateScans < ActiveRecord::Migration[8.1]
  def change
    create_table :scans do |t|
      t.string :url
      t.string :site_name
      t.float :risk_score
      t.text :full_report

      t.timestamps
    end
  end
end
