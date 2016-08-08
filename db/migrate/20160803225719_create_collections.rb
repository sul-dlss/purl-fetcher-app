class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :druid, null: false
      t.timestamps null: false
    end
    add_index :collections, :druid
  end
end
