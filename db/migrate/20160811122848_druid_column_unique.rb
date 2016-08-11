class DruidColumnUnique < ActiveRecord::Migration
  def change
    remove_index :purls, :druid
    add_index :purls, :druid, unique: true
    remove_index :collections, :druid
    add_index :collections, :druid, unique: true
  end
end
