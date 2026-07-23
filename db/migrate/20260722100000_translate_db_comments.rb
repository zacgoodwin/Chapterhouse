# frozen_string_literal: true

# Prod DB comments were written in Russian by the upstream migrations; the
# repo migrations and schema.rb are translated, so sync the live DB to the
# exact schema.rb texts. Generated from db/schema.rb; a fresh
# db:schema:load already produces these, making this a no-op there.
class TranslateDbComments < ActiveRecord::Migration[8.1]
  TABLE_COMMENTS = {
    character_feats: 'Character feats',
    characters: 'Characters',
    feats: 'Feats',
    homebrew_subclasses: 'Custom subclasses',
    items: 'Items',
    spells: 'Spells',
    user_homebrews: 'Precomputed list of all available homebrew'
  }.freeze

  COLUMN_COMMENTS = {
    character_feats: {
      active: 'Whether the feat effect is enabled',
      limit_refresh: 'Event that refreshes the limit',
      tokens: 'Current token count',
      used_count: 'Uses count',
      value: 'Selected feat options or entered text'
    },
    character_items: {
      data: 'Equipped item properties',
      name: 'Customized item name'
    },
    character_spells: {
      data: 'Prepared spell properties'
    },
    characters: {
      data: 'Character properties',
      type: 'Game system the character was created for'
    },
    custom_resources: {
      reset_direction: '0 - reset to zero, 1 - reset to maximum'
    },
    feats: {
      conditions: 'Feat availability conditions',
      continious: 'Whether the feat has a toggleable effect',
      description_eval_variables: 'Evaluated variables for description',
      eval_variables: 'Evaluated variables',
      exclude: 'Replaced feats',
      limit_refresh: 'Event that refreshes the limit',
      options: 'Selection options',
      origin: 'Feat applicability type',
      origin_value: 'Feat applicability value',
      origin_values: 'Multiple origins that can have the feat',
      price: 'Feature activation price',
      reset_on_rest: 'Reset selection on rest',
      tokens: 'Token settings for feats'
    },
    homebrew_books: {
      public: 'Open access for other users'
    },
    homebrew_subclasses: {
      class_name: 'Class name or custom class ID',
      public: 'Open access for other users',
      type: 'Game system association'
    },
    items: {
      data: 'Item properties',
      kind: 'Item kind',
      public: 'Open access for other users'
    },
    notifications: {
      locale: 'Recipient user locale',
      targets: 'Notification targets'
    },
    spells: {
      data: 'Spell properties'
    }
  }.freeze

  def up
    TABLE_COMMENTS.each { |table, comment| change_table_comment(table, comment) }
    COLUMN_COMMENTS.each do |table, columns|
      columns.each { |column, comment| change_column_comment(table, column, comment) }
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
