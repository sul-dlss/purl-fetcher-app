class CreateRunLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :run_logs do |t|
      t.integer :total_druids
      t.integer :num_errors
      t.string :finder_filename
      t.string :note
      t.datetime :started
      t.datetime :ended
      t.timestamps null: false
    end
  end
end
