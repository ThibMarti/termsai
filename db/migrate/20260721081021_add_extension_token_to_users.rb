class AddExtensionTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :extension_token, :string
    add_index :users, :extension_token, unique: true
  end
end
