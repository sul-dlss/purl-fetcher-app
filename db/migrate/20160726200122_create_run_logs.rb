class CreateRunLogs < ActiveRecord::Migration
  def change
    create_table :run_logs do |t|
      t.integer :total_druids
      t.integer :num_errors
      t.string :note
      t.datetime :started
      t.datetime :ended
      t.timestamps null: false
    end
  end
end
