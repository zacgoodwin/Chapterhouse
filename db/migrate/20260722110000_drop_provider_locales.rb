# frozen_string_literal: true

# Dead column after the English-only conversion: provider_locales held
# per-provider alternative translations and has zero remaining readers or
# writers in app/, lib/, or config/. safety_assured: with no code referencing
# the column the only exposure is INSERTs from old machines during the Fly
# release window (seconds, near-zero traffic on this app), and the
# strong_migrations initializer already caps lock_timeout at 10s.
class DropProviderLocales < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :users, :provider_locales, :jsonb, default: {} }
  end
end
