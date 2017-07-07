class AddPublishedAtToPurl < ActiveRecord::Migration[5.0]
  def change
    add_column :purls, :published_at, :datetime
    remove_column :purls, :indexed_at
    add_index :purls, :published_at
  end
end
