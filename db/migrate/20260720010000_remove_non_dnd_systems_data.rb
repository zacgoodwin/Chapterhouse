# frozen_string_literal: true

# Deletes all rows belonging to the removed game systems (pathfinder2,
# daggerheart, dc20, fate, fallout, cosmere, cthulhu7). Raw SQL only: the
# STI classes no longer exist, so model-level deletes would raise
# ActiveRecord::SubclassNotFound. There are no DB-level FK cascades
# (dependent-destroy lived in the models), so children go first.
class RemoveNonDndSystemsData < ActiveRecord::Migration[7.2]
  CHARACTER_TYPES = %w[
    Pathfinder2::Character Daggerheart::Character Dc20::Character
    Fate::Character Fallout::Character Cosmere::Character Cthulhu7::Character
  ].freeze
  FEAT_TYPES = %w[Pathfinder2::Feat Daggerheart::Feat Dc20::Feat Fallout::Feat Cosmere::Feat].freeze
  ITEM_TYPES = %w[Pathfinder2::Item Daggerheart::Item Dc20::Item Fallout::Item Cosmere::Item Cthulhu7::Item].freeze
  KEPT_SPELL_TYPES = %w[Dnd5::Spell Dnd2024::Spell].freeze
  PROVIDERS = %w[pathfinder2 daggerheart dc20 fate fallout cosmere cthulhu7].freeze
  STI_PREFIXES = %w[Pathfinder2:: Daggerheart:: Dc20:: Fate:: Fallout:: Cosmere:: Cthulhu7::].freeze

  def up
    safety_assured do
      remove_characters
      remove_campaigns
      remove_content
      remove_homebrews
      reset_user_caches
      drop_table :daggerheart_projects
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def quoted(values)
    values.map { |value| ActiveRecord::Base.connection.quote(value) }.join(', ')
  end

  def remove_characters
    chars = "SELECT id FROM characters WHERE type IN (#{quoted(CHARACTER_TYPES)})"
    companions = "SELECT id FROM character_companions WHERE character_id IN (#{chars})"

    execute "DELETE FROM character_bonus WHERE bonusable_type = 'Character::Companion' AND bonusable_id IN (#{companions})"
    execute "DELETE FROM character_bonus WHERE bonusable_type = 'Character' AND bonusable_id IN (#{chars})"
    execute "DELETE FROM character_companions WHERE character_id IN (#{chars})"
    %w[character_feats character_items character_spells character_notes character_resources].each do |table|
      execute "DELETE FROM #{table} WHERE character_id IN (#{chars})"
    end
    execute "DELETE FROM custom_resources WHERE resourceable_type = 'Character' AND resourceable_id IN (#{chars})"
    execute "DELETE FROM campaign_characters WHERE character_id IN (#{chars})"
    execute "DELETE FROM active_storage_attachments WHERE record_type = 'Character' AND record_id IN (#{chars})"
    execute "DELETE FROM characters WHERE type IN (#{quoted(CHARACTER_TYPES)})"
  end

  def remove_campaigns
    camps = "SELECT id FROM campaigns WHERE provider IN (#{quoted(PROVIDERS)})"

    %w[campaign_characters campaign_items campaign_notes campaign_channels channels].each do |table|
      execute "DELETE FROM #{table} WHERE campaign_id IN (#{camps})"
    end
    execute "DELETE FROM custom_resources WHERE resourceable_type = 'Campaign' AND resourceable_id IN (#{camps})"
    execute "DELETE FROM campaigns WHERE provider IN (#{quoted(PROVIDERS)})"
  end

  # feats, the items they own, standalone items, and non-dnd spells
  def remove_content
    feats = "SELECT id FROM feats WHERE type IN (#{quoted(FEAT_TYPES)})"
    items = "SELECT id FROM items WHERE type IN (#{quoted(ITEM_TYPES)}) " \
            "OR (itemable_type = 'Feat' AND itemable_id IN (#{feats}))"
    spells = "SELECT id FROM spells WHERE type NOT IN (#{quoted(KEPT_SPELL_TYPES)})"

    execute "DELETE FROM character_items WHERE item_id IN (#{items})"
    execute "DELETE FROM campaign_items WHERE item_id IN (#{items})"
    execute "DELETE FROM item_recipes WHERE tool_id IN (#{items}) OR item_id IN (#{items})"
    execute "DELETE FROM character_bonus WHERE bonusable_type = 'Item' AND bonusable_id IN (#{items})"
    execute "DELETE FROM upvotes WHERE upvoteable_id IN (#{items})"
    execute "DELETE FROM homebrew_book_items WHERE itemable_id IN (#{items})"
    execute "DELETE FROM items WHERE id IN (#{items})"

    execute "DELETE FROM character_feats WHERE feat_id IN (#{feats})"
    execute "DELETE FROM character_bonus WHERE bonusable_type = 'Feat' AND bonusable_id IN (#{feats})"
    execute "DELETE FROM upvotes WHERE upvoteable_id IN (#{feats})"
    execute "DELETE FROM homebrew_book_items WHERE itemable_id IN (#{feats})"
    execute "DELETE FROM feats WHERE id IN (#{feats})"

    execute "DELETE FROM character_spells WHERE spell_id IN (#{spells})"
    execute "DELETE FROM spells WHERE id IN (#{spells})"
  end

  def remove_homebrews
    sti_conditions = STI_PREFIXES.map { |prefix| "type LIKE '#{prefix}%'" }.join(' OR ')
    homebrews = "SELECT id FROM homebrews WHERE #{sti_conditions}"
    books = "SELECT id FROM homebrew_books WHERE provider IN (#{quoted(PROVIDERS)})"
    # provider NULL predates the column and always meant daggerheart
    publications = "SELECT id FROM homebrew_publications WHERE provider IS DISTINCT FROM 'dnd2024'"

    execute "DELETE FROM upvotes WHERE upvoteable_id IN (#{homebrews})"
    execute "DELETE FROM homebrew_book_items WHERE itemable_id IN (#{homebrews})"
    execute "DELETE FROM homebrews WHERE id IN (#{homebrews})"
    execute "DELETE FROM homebrew_subclasses WHERE #{sti_conditions}"

    execute "DELETE FROM user_books WHERE homebrew_book_id IN (#{books})"
    execute "DELETE FROM homebrew_book_items WHERE homebrew_book_id IN (#{books})"
    execute "DELETE FROM upvotes WHERE upvoteable_id IN (#{books})"
    execute "DELETE FROM homebrew_books WHERE id IN (#{books})"

    execute "DELETE FROM active_storage_attachments WHERE record_type = 'Homebrew::Publication' AND record_id IN (#{publications})"
    execute "DELETE FROM homebrew_publications WHERE id IN (#{publications})"

    itemable_conditions = STI_PREFIXES.map { |prefix| "itemable_type LIKE '#{prefix}%'" }.join(' OR ')
    execute "DELETE FROM homebrew_book_items WHERE #{itemable_conditions}"
  end

  def reset_user_caches
    execute 'DELETE FROM user_homebrews' # regenerated by HomebrewsContext::RefreshUserDataService
    execute "UPDATE users SET provider_locales = '{}'::jsonb"
    execute "DELETE FROM user_platforms WHERE name IN (#{quoted(PROVIDERS)})"
  end
end
