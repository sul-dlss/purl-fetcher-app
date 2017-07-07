class PurlsCollections < ActiveRecord::Migration[5.0]
  def change
    create_table :collections_purls, id: false do |t|
      t.belongs_to :purl, index: true
      t.belongs_to :collection, index: true
    end
  end
end
