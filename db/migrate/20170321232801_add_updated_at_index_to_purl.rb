class AddUpdatedAtIndexToPurl < ActiveRecord::Migration[5.0]
  def change
    add_index :purls, :updated_at
  end
end
