# frozen_string_literal: true

# English-only conversion: the repo's seed data dropped its ru/es locale
# values, so strip them from the already-seeded content too, and fix the
# upstream seed bugs that lived in that data (Cyrillic homoglyphs inside
# stonecunning and pact_of_the_tome, a Russian title on gaze_of_two_minds,
# and five slugs containing spaces). The homebrew_* tables are untouched, and
# every typo repair targets seeded rows only (user_id IS NULL) so a
# user-authored row sharing a slug can never be renamed or collide with the
# unique (type, slug) index. The ru/es strips DO include user-authored rows
# in feats/items by design -- the whole app is English-only now.
class EnglishOnlyContent < ActiveRecord::Migration[8.1]
  # upstream slug had a Cyrillic homoglyph (U+0441) in place of the latin c;
  # the spaced slugs are upstream typos (siblings use underscores)
  BROKEN_SLUGS = {
    "stone\u0441unning" => 'stonecunning',
    'boon of recovery' => 'boon_of_recovery',
    'unarmed fighting' => 'unarmed_fighting',
    'blind fighting' => 'blind_fighting',
    'persistent rage' => 'persistent_rage',
    'beast spells' => 'beast_spells'
  }.freeze

  def up
    fix_seed_typos
    strip_locale_values

    execute "UPDATE users SET locale = 'en' WHERE locale <> 'en'"
    change_column_default :items, :description, from: { en: '', ru: '' }, to: { en: '' }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def fix_seed_typos
    BROKEN_SLUGS.each do |from, to|
      execute ActiveRecord::Base.sanitize_sql(
        ['UPDATE feats SET slug = ? WHERE slug = ? AND user_id IS NULL', to, from]
      )
    end
    execute <<~SQL.squish
      UPDATE feats SET title = jsonb_set(title, '{en}', '"Stonecunning"')
      WHERE slug = 'stonecunning' AND user_id IS NULL
    SQL
    execute <<~SQL.squish
      UPDATE feats SET title = jsonb_set(title, '{en}', '"Gaze of Two Minds"')
      WHERE slug = 'gaze_of_two_minds' AND user_id IS NULL
    SQL
    # upstream seed had a Cyrillic C homoglyph (U+0421) in this description;
    # jsonb_exists guard because jsonb_set is strict on a missing en key
    execute ActiveRecord::Base.sanitize_sql(
      [<<~SQL.squish, "\u0421hoose", 'Choose']
        UPDATE feats
        SET description = jsonb_set(description, '{en}', to_jsonb(replace(description->>'en', ?, ?)))
        WHERE slug = 'pact_of_the_tome' AND user_id IS NULL AND jsonb_exists(description, 'en')
      SQL
    )
  end

  def strip_locale_values
    execute <<~SQL.squish
      UPDATE feats SET title = title - 'ru' - 'es', description = description - 'ru' - 'es'
      WHERE title ?| array['ru','es'] OR description ?| array['ru','es']
    SQL
    # options values are {slug => {en:, ru:, es:}} locale dicts; typeof guard
    # because adminbook accepts free-text JSON and jsonb_each raises on non-objects
    execute <<~SQL.squish
      UPDATE feats
      SET options = (
        SELECT jsonb_object_agg(k, CASE WHEN jsonb_typeof(v) = 'object' THEN v - 'ru' - 'es' ELSE v END)
        FROM jsonb_each(options) AS e(k, v)
      )
      WHERE options IS NOT NULL AND options <> '{}'::jsonb AND jsonb_typeof(options) = 'object'
    SQL
    execute "UPDATE spells SET name = name - 'ru' - 'es' WHERE name ?| array['ru','es']"
    execute <<~SQL.squish
      UPDATE items SET name = name - 'ru' - 'es', description = description - 'ru' - 'es'
      WHERE name ?| array['ru','es'] OR description ?| array['ru','es']
    SQL
  end
end
