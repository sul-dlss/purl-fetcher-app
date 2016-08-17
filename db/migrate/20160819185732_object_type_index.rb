class ObjectTypeIndex < ActiveRecord::Migration
  def change
    add_index :purls, :object_type
  end
end
