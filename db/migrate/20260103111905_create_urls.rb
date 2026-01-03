class CreateUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :urls do |t|
      t.text :long_url, null: false
      t.string :long_url_hash, null: false
      t.string :short_code

      t.timestamps
    end
    add_index :urls, :long_url_hash, unique: true
    add_index :urls, :short_code, unique: true
  end
end
