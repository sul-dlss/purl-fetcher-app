class DropRunLogs < ActiveRecord::Migration[5.0]
  def change
    drop_table :run_logs
  end
end
