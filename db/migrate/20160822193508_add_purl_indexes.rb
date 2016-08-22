class AddPurlIndexes < ActiveRecord::Migration
  def change
    add_index :purls, [:published_at, :deleted_at]
  end
end
