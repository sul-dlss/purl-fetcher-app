class EnforceUniqueReleaseTags < ActiveRecord::Migration
  def change
    add_index :release_tags, [ :name, :purl_id ], unique: true
  end
end
