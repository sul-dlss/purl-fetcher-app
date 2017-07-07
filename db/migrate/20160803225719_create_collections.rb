class CreateCollections < ActiveRecord::Migration[5.0]
  def change
    create_table :collections do |t|
      t.string :druid, null: false
      t.timestamps null: false
    end
    add_index :collections, :druid
  end
end
