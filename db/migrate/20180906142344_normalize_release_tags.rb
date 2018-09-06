class NormalizeReleaseTags < ActiveRecord::Migration[5.0]
  def up
    ReleaseTag.connection.execute('UPDATE release_tags SET `name` = UPPER( `name` )')
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
