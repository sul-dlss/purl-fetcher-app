class CreateReleaseTags < ActiveRecord::Migration
  def change
    create_table :release_tags do |t|
      t.string :name, null: false
      t.boolean :release_type, null: false
      t.integer :purl_id, null: false
      t.timestamps null: false
    end
    add_index :release_tags, :purl_id
    add_index :release_tags, :release_type
  end
end
