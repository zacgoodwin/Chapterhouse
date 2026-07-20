# frozen_string_literal: true

# Partial unique index on (type, slug) for the three TLC content tables, scoped
# to `type LIKE 'Tlc::%'` so it never touches the dnd5/dnd2024 rows that share
# these tables (their slugs are intentionally non-unique, see db/seeds.rb).
# It is the ON CONFLICT arbiter for `rake tlc:seed`'s upsert_all(unique_by:),
# which is what makes re-seeding idempotent (eng finding 3: no unique index on
# feats.slug or spells.slug exists today). Additive and zero-downtime: built
# CONCURRENTLY, covers only rows that don't exist yet.
class AddTlcUniqueContentIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  TLC_SCOPE = "type LIKE 'Tlc::%'"

  def change
    add_index :feats, %i[type slug], unique: true, where: TLC_SCOPE,
              name: 'index_feats_on_type_and_slug_tlc', algorithm: :concurrently
    add_index :spells, %i[type slug], unique: true, where: TLC_SCOPE,
              name: 'index_spells_on_type_and_slug_tlc', algorithm: :concurrently
    add_index :items, %i[type slug], unique: true, where: TLC_SCOPE,
              name: 'index_items_on_type_and_slug_tlc', algorithm: :concurrently
  end
end
