class FixFullReportToJsonb < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM user_scans"   # purge les scans de test au format cassé
    execute "DELETE FROM scans"
    change_column :scans, :full_report, :jsonb, using: "full_report::jsonb", default: {}
  end

  def down
    change_column :scans, :full_report, :text
  end
end
