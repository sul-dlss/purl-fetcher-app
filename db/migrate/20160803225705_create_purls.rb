class CreatePurls < ActiveRecord::Migration[5.0]
  def change
    create_table :purls do |t|
      t.string :druid, null: false
      t.string :title
      t.string :object_type
      t.string :catkey
      t.timestamp :deleted_at
      t.timestamp :indexed_at
      t.timestamps null: false
    end
    add_index :purls, :druid
    add_index :purls, :deleted_at
    add_index :purls, :indexed_at
  end
end
