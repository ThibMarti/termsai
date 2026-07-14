class ChangeFullReportToJsonb < ActiveRecord::Migration[8.1]
  def change
  end

  def up
    change_column :scans, :full_report, :jsonb, using: "full_report::jsonb", default: {}
  end

  def down
    change_column :scans, :full_report, :text
  end
end
