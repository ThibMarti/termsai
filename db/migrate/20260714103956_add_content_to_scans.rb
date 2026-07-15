class AddContentToScans < ActiveRecord::Migration[8.1]
  def change
    add_column :scans, :content, :text
  end
end
