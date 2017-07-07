class CreateListenerLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :listener_logs do |t|
      t.integer :process_id, null: false    # UNIX pid for listener daemon
      t.timestamp :started_at, null: false  # when the listener was started
      t.timestamp :active_at                # last time the listener did anything
      t.timestamp :ended_at                 # when the listener was stopped
      t.timestamps null: false              # Rails-managed create/update times
    end
    add_index :listener_logs, :process_id
    add_index :listener_logs, :started_at
  end
end
