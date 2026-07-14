class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.string :url
      t.text :raw_text

      t.timestamps
    end
  end
end
