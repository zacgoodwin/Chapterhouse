# frozen_string_literal: true

# Supabase Auth owns credentials and OAuth identities now; sessions are
# managed client-side by supabase-js and users.id == auth.users.id.
class DropAuthkeeperTables < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      drop_table :user_sessions
      drop_table :user_identities
      remove_column :users, :password_digest
      remove_column :users, :russian_login
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
