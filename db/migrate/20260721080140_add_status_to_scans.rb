class AddStatusToScans < ActiveRecord::Migration[8.1]
  def change
    add_column :scans, :status, :string, default: "processing"
  end
end
