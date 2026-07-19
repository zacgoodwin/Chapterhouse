# frozen_string_literal: true

class RemoveTelegramProviderData < ActiveRecord::Migration[8.1]
  # provider = 0 was the telegram enum value in both tables; raw SQL because the
  # model enums no longer contain it
  def up
    safety_assured do
      execute 'DELETE FROM campaign_channels WHERE channel_id IN (SELECT id FROM channels WHERE provider = 0)'
      execute 'DELETE FROM channels WHERE provider = 0'
      execute 'DELETE FROM user_identities WHERE provider = 0'
      execute "UPDATE notifications SET targets = array_remove(targets, 'telegram')"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
