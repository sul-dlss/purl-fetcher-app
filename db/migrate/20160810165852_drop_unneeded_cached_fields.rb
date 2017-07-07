class DropUnneededCachedFields < ActiveRecord::Migration[5.0]
  def change
    remove_column :purls, :title
    remove_column :purls, :catkey
  end
end
