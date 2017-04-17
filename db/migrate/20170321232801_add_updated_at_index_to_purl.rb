class AddUpdatedAtIndexToPurl < ActiveRecord::Migration
  def change
    add_index :purls, :updated_at
  end
end
