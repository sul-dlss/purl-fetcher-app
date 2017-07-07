class AddColumnsBack < ActiveRecord::Migration[5.0]
  def change
    add_column :purls, :title, :text
    add_column :purls, :catkey, :string
  end
end
