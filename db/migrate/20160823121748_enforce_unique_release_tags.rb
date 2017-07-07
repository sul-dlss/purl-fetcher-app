class EnforceUniqueReleaseTags < ActiveRecord::Migration[5.0]
  def change
    add_index :release_tags, [ :name, :purl_id ], unique: true
  end
end
