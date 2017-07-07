class ObjectTypeIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :purls, :object_type
  end
end
