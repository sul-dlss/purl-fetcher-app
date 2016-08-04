class CreatePurls < ActiveRecord::Migration
  def change
    create_table :purls do |t|
      t.string :druid, null: false
      t.string :title
      t.string :object_type
      t.string :catkey
      t.timestamp :deleted_at
      t.timestamps null: false
    end
    add_index :purls, :druid
    add_index :purls, :deleted_at
    add_index :purls, :updated_at
  end
end
