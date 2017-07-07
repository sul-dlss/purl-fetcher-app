class AddPurlIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :purls, [:published_at, :deleted_at]
  end
end
