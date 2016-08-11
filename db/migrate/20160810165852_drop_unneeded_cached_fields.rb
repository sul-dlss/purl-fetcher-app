class DropUnneededCachedFields < ActiveRecord::Migration
  def change
    remove_column :purls, :title
    remove_column :purls, :catkey
  end
end
