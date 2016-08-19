class AddColumnsBack < ActiveRecord::Migration
  def change
    add_column :purls, :title, :text
    add_column :purls, :catkey, :string
  end
end
