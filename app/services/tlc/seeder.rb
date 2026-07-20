# frozen_string_literal: true

module Tlc
  # Idempotent loader for TLC homebrew content (db/data/tlc/*.json), driven by
  # `rake tlc:seed`. Upserts each file against the partial unique (type, slug)
  # index added by AddTlcUniqueContentIndex, so re-running never duplicates rows
  # (eng finding 3 / acceptance test 9). The legacy db/seeds.rb is non-idempotent
  # and out of scope.
  #
  # Two guards run before any write:
  #   1. Malformed JSON aborts loudly. JSON::ParserError propagates with the
  #      filename so the dev sees the stacktrace (Error Registry: not rescued).
  #   2. Any content row whose modifiers auto-grant a campaign-banned spell aborts
  #      naming the row, unless it carries `banned_exemption: true` (decision 23,
  #      the systematic rule that catches the Lady of Ivory to Fabricate conflict
  #      class, not just the known instance). The runtime soft-warning for an
  #      exempted grant is C7's job; here the flag only suppresses the abort.
  #
  # Rows use an author-friendly shape, mapped to DB columns here:
  #   slug, title:{en,..}, description:{en,..} or a bare String, origin,
  #   origin_value, kind, limit_refresh, modifiers, eval_variables, conditions,
  #   info/data, available_for, and the meta flags unlock / verified /
  #   banned_exemption (folded into the model's jsonb meta column: `info` for
  #   feats and items, `data` for spells).
  class Seeder
    class BannedGrantError < StandardError; end

    # Campaign-banned spells (plan Phase B). Slugs, not display names: note
    # `dream_of_the_blue_veil` (planar travel), which is NOT the unrelated PHB
    # `dream` spell. The tlc spell-options filter (a later ticket) reuses this
    # list; it lives here until that second consumer lands, then lifts to a
    # shared home.
    BANNED_SPELL_SLUGS = %w[
      demiplane dream_of_the_blue_veil earthquake fabricate
      plane_shift teleport tsunami wind_walk
    ].freeze

    # filename stem -> STI model. species_traits and feats both land as Tlc::Feat.
    FILE_MODELS = {
      'species_traits' => 'Tlc::Feat',
      'feats' => 'Tlc::Feat',
      'spells' => 'Tlc::Spell',
      'items' => 'Tlc::Item'
    }.freeze

    # Partial unique index name per content table (the ON CONFLICT arbiter).
    UNIQUE_INDEX = {
      'feats' => :index_feats_on_type_and_slug_tlc,
      'spells' => :index_spells_on_type_and_slug_tlc,
      'items' => :index_items_on_type_and_slug_tlc
    }.freeze

    # jsonb column the meta flags fold into, keyed by STI class name.
    META_COLUMN = { 'Tlc::Feat' => :info, 'Tlc::Item' => :info, 'Tlc::Spell' => :data }.freeze

    def self.call(...) = new(...).call

    def initialize(dir:, out: $stdout)
      @dir = Pathname.new(dir.to_s)
      @out = out
    end

    def call
      counts = {}
      unverified = 0

      FILE_MODELS.each do |stem, model_name|
        path = @dir.join("#{stem}.json")
        next unless path.exist?

        count, file_unverified = seed_file(path, model_name.constantize)
        counts[stem] = count
        unverified += file_unverified
      end

      report(counts, unverified)
      { counts: counts, unverified: unverified }
    end

    private

    def seed_file(path, model)
      rows = parse(path)
      rows.each { |row| lint_banned_grants!(row, path) }
      built = rows.map { |row| build_row(row, model) }
      model.upsert_all(built, unique_by: UNIQUE_INDEX.fetch(model.table_name)) if built.any?
      [built.size, built.count { |row| row[META_COLUMN.fetch(model.name)]['verified'] == false }]
    end

    def parse(path)
      data = JSON.parse(File.read(path)) # JSON::ParserError propagates (loud abort, per Error Registry).
      raise "#{path}: expected a JSON array of content rows, got #{data.class}" unless data.is_a?(Array)

      data
    end

    # A row auto-grants a spell through two real surfaces in this codebase: a
    # static hash at info.static_spells ({slug => config}, the import path) and a
    # Dentaku merge string at eval_variables.static_spells (the hand-authored
    # path, e.g. "static_spells.merge({ 'elementalism': {...} })"). Scan both.
    def lint_banned_grants!(row, path)
      hits = granted_spell_slugs(row) & BANNED_SPELL_SLUGS
      return if hits.empty?
      return if row['banned_exemption'] == true

      raise BannedGrantError,
            "#{path}: row '#{row['slug']}' auto-grants banned spell(s) " \
            "#{hits.sort.join(', ')} without `banned_exemption: true` (decision 23)"
    end

    def granted_spell_slugs(row)
      slugs = []
      static = row.dig('info', 'static_spells')
      slugs.concat(static.keys) if static.is_a?(Hash)
      evaled = row.dig('eval_variables', 'static_spells')
      # Keys are quoted literals right before a colon: 'fabricate': {...}. Matching
      # the whole quoted token stops `teleport` matching `teleportation_circle`.
      slugs.concat(evaled.scan(/['"]([a-z0-9_]+)['"]\s*:/).flatten) if evaled.is_a?(String)
      slugs
    end

    def build_row(row, model)
      { type: model.name, slug: row.fetch('slug') }.merge(columns_for(row, model))
    end

    def columns_for(row, model)
      case model.name
      when 'Tlc::Feat' then feat_columns(row)
      when 'Tlc::Spell' then spell_columns(row)
      when 'Tlc::Item' then item_columns(row)
      end
    end

    def feat_columns(row)
      {
        title: jsonb_text(row['title']),
        description: jsonb_text(row['description']),
        origin_value: row['origin_value'],
        modifiers: row['modifiers'] || {},
        eval_variables: row['eval_variables'] || {},
        conditions: row['conditions'] || {},
        info: build_meta(row, 'info')
      }.merge(feat_enums(row))
    end

    # Enum columns store ints; upsert_all bypasses ActiveRecord's enum casting, so
    # map the author-facing strings to their ints here (like create! would).
    def feat_enums(row)
      {
        origin: ::Tlc::Feat.origins.fetch(row.fetch('origin')),
        kind: ::Tlc::Feat.kinds.fetch(row.fetch('kind')),
        limit_refresh: row['limit_refresh'] && ::Tlc::Feat.limit_refreshes.fetch(row['limit_refresh'])
      }
    end

    def spell_columns(row)
      {
        name: jsonb_text(row['title'] || row['name']),
        available_for: row['available_for'],
        data: build_meta(row, 'data')
      }
    end

    def item_columns(row)
      {
        name: jsonb_text(row['title'] || row['name']),
        kind: row.fetch('kind'),
        modifiers: row['modifiers'] || {},
        info: build_meta(row, 'info')
      }
    end

    # unlock/verified/banned_exemption are meta, not columns: fold them into the
    # model's jsonb meta column, merged over any explicit info/data the row has.
    # verified defaults to true so only garbled content-gate rows read false.
    def build_meta(row, base_key)
      meta = (row[base_key] || {}).dup
      meta['unlock'] = row['unlock'] if row.key?('unlock')
      meta['verified'] = row.fetch('verified', true)
      meta['banned_exemption'] = row['banned_exemption'] if row.key?('banned_exemption')
      meta
    end

    # Accept a localized hash ({en:..}) as-is or wrap a bare String as {en:..}.
    def jsonb_text(value)
      return value if value.is_a?(Hash)
      return { 'en' => value } if value.is_a?(String)

      {}
    end

    def report(counts, unverified)
      @out.puts 'tlc:seed upserted TLC content:'
      FILE_MODELS.each_key { |stem| @out.puts "  #{stem.ljust(16)} #{counts.fetch(stem, 0)}" }
      @out.puts "  unverified rows  #{unverified}"
    end
  end
end
