# frozen_string_literal: true

module Tlc
  # Soft-warning engine (plan L415-418; design-doc-digest §Top-10 #1 "never
  # block"). Every entry is dismissible and names its source so the banner can
  # say whether the broken rule comes from the PHB or from TLC. Nothing here
  # rejects, blocks, or mutates -- a rule-breaking-but-real choice is always
  # saved and then warned about (plan L715).
  #
  # At most ONE entry per slug. Dismissals are keyed by slug alone (decision 19:
  # no context-hash re-arming), so two entries sharing a slug could not be
  # dismissed independently; each check aggregates its offenders into `context`.
  #
  # Deliberately NOT inside TlcDecorator, even though the plan sketches it there:
  # spec/decorators_v2/tlc_decorator_spec.rb asserts TlcDecorator's `@result`
  # stays byte-identical to Dnd2024Decorator's for a delta-free character, and
  # writing `warnings` into `@result` would kill that parity alarm on every TLC
  # sheet. The serializer calls this with the decorator it already built, so the
  # decorated values are read, never recomputed.
  class Warnings
    PHB = 'PHB'
    TLC = 'TLC'

    # THE registry (plan §Code Quality). The i18n message key and the
    # `data.dismissed_warnings` entry are both derived from these slugs, so the
    # two cannot drift; adding a warning means adding a row here, a private
    # method named after the slug, and an en.json entry -- spec/lib/tlc/
    # warnings_spec.rb fails on any of the three going missing.
    SLUGS = {
      'multiclass_prereq' => PHB,
      'trait_count' => TLC,
      'prepared_overrun' => PHB,
      'level_vs_chapter_cap' => TLC,
      'banned_spell_exempted' => TLC,
      'trait_unavailable' => TLC
    }.freeze

    # PHB 2024 multiclass prerequisites. Outer array is AND, inner is OR, so
    # Fighter's "Strength or Dexterity 13" and Paladin's "Strength and
    # Charisma 13" share one shape instead of needing two code paths.
    MULTICLASS_PREREQS = {
      'artificer' => [%w[int]],
      'barbarian' => [%w[str]],
      'bard' => [%w[cha]],
      'cleric' => [%w[wis]],
      'druid' => [%w[wis]],
      'fighter' => [%w[str dex]],
      'monk' => [%w[dex], %w[wis]],
      'paladin' => [%w[str], %w[cha]],
      'ranger' => [%w[dex], %w[wis]],
      'rogue' => [%w[dex]],
      'sorcerer' => [%w[cha]],
      'warlock' => [%w[cha]],
      'wizard' => [%w[int]]
    }.freeze
    MULTICLASS_MINIMUM = 13

    # Human Greenhorn: humans ignore multiclassing ability prerequisites
    # (players-guide-digest.md:60 and the species table at :77). Mixed Ancestry
    # counts -- half a Human is still a Human for this trait.
    GREENHORN_SPECIES = 'human'

    # Players Guide Table 2 (§10): max level by campaign chapter, ch8->12
    # through ch16->20. Chapters outside that range have no published cap, so
    # they raise no warning rather than guessing one. The `chapter` field itself
    # is campaign bookkeeping owned by C6 (#22).
    LEVEL_CAP_BY_CHAPTER = (8..16).index_with { |chapter| chapter + 4 }.freeze

    BASE_TRAIT_ALLOWANCE = 3
    MIXED_ANCESTRY_TRAIT_ALLOWANCE = 4

    SPELL_ORIGIN = 6

    def self.message_key(slug) = "warnings.#{slug.camelize(:lower)}"

    def self.call(decorator:) = new(decorator).call

    def initialize(decorator)
      @decorator = decorator
      @character = decorator.parent
      @data = decorator.data
    end

    # Dispatching off the registry is what keeps the two in step: a slug with no
    # method raises NoMethodError the first time a TLC sheet is serialized.
    def call
      SLUGS.each_key.filter_map { |slug| send(slug) }
    end

    private

    def warning(slug, context)
      {
        slug: slug,
        source: SLUGS.fetch(slug),
        message_key: self.class.message_key(slug),
        dismissible: true,
        context: context
      }
    end

    def multiclass_prereq
      return if classes.size < 2
      return if greenhorn?

      unmet = classes.keys.reject { |class_slug| multiclass_prereq_met?(class_slug) }
      return if unmet.empty?

      warning(
        'multiclass_prereq',
        { classes: unmet, required: unmet.index_with { |slug| MULTICLASS_PREREQS.fetch(slug, []) },
          minimum: MULTICLASS_MINIMUM }
      )
    end

    def trait_count
      allowed = @data.mixed_species.present? ? MIXED_ANCESTRY_TRAIT_ALLOWANCE : BASE_TRAIT_ALLOWANCE
      return if selected_traits.size <= allowed

      warning('trait_count', { selected: selected_traits.size, allowed: allowed })
    end

    def prepared_overrun
      allowances = prepared_allowances
      return if allowances.empty?

      over = prepared_counts.filter_map { |class_slug, count|
        allowed = allowances[class_slug]
        [class_slug, { prepared: count, allowed: allowed }] if allowed && count > allowed
      }.to_h
      return if over.empty?

      warning('prepared_overrun', over)
    end

    def level_vs_chapter_cap
      chapter = campaign_chapter
      cap = LEVEL_CAP_BY_CHAPTER[chapter]
      return if cap.nil? || level <= cap

      warning('level_vs_chapter_cap', { level: level, cap: cap, chapter: chapter })
    end

    # The exemption flag lives on the GRANTING content row: the seed lint fails
    # any row that auto-grants a banned spell unless it carries
    # `banned_exemption: true` (plan L337-343), so an ATTACHED row carrying the
    # flag is by definition an exempted banned grant. Reading the flag beats
    # re-deriving membership from Tlc::Feat::BANNED_SPELL_SLUGS (C5, #21): it
    # needs no cross-lane constant and it names the granting feature, which the
    # banner message wants (the Lady of Ivory -> Fabricate case).
    #
    # All three content tables, because Tlc::Seeder lints all three
    # (seeder.rb FILE_MODELS) -- an exempted ITEM would otherwise pass the seed
    # gate and then never warn at runtime.
    def banned_spell_exempted
      granting = {
        feats: exempted(@character.feats, :feat, 'feats', 'info'),
        items: exempted(@character.items, :item, 'items', 'info'),
        spells: exempted(@character.spells, :spell, 'spells', 'data')
      }.reject { |_kind, slugs| slugs.empty? }
      return if granting.empty?

      warning('banned_spell_exempted', granting)
    end

    # The flag folds into the content row's jsonb meta column, which the seeder
    # names `info` for feats and items and `data` for spells
    # (seeder.rb META_COLUMN). Table and column are literals from the three call
    # sites above, never input.
    def exempted(relation, association, table, meta_column)
      relation.joins(association)
        .where("#{table}.#{meta_column} -> 'banned_exemption' = 'true'::jsonb")
        .pluck(Arel.sql("#{table}.slug")).compact
    end

    # C2's refresh service skips a selected trait whose content row was deleted;
    # this is where that silent skip surfaces (plan L682, auto-decision 15).
    def trait_unavailable
      return if selected_traits.empty?

      missing = selected_traits - ::Feat.tlc_content.where(slug: selected_traits).pluck(:slug)
      return if missing.empty?

      warning('trait_unavailable', { traits: missing })
    end

    def multiclass_prereq_met?(class_slug)
      MULTICLASS_PREREQS.fetch(class_slug, []).all? { |group|
        group.any? { |ability| abilities[ability].to_i >= MULTICLASS_MINIMUM }
      }
    end

    def greenhorn? = [@data.species, @data.mixed_species].include?(GREENHORN_SPECIES)

    # Decorated scores where the decorator computed them; the raw ones under
    # `simple: true`, where the decorator returns before applying bonuses.
    def abilities = @decorator.modified_abilities.presence || @data.abilities || {}

    def classes = @data.classes || {}

    def level = @data.level.to_i

    def selected_traits = @data.selected_traits || []

    def prepared_allowances
      (@decorator.spell_classes || {}).each_with_object({}) do |(class_slug, info), acc|
        amount = info[:prepared_spells_amount]
        acc[class_slug] = amount if amount
      end
    end

    # Cantrips are always available and are never "prepared" (PHB 2024), so
    # level-0 rows stay out of the count.
    def prepared_counts
      @character.feats
        .joins(:feat)
        .where(feats: { origin: SPELL_ORIGIN }, ready_to_use: true)
        .where("COALESCE(feats.info ->> 'level', '0') <> '0'")
        .group(Arel.sql("character_feats.value ->> 'prepared_by'"))
        .count
    end

    # A PC in two campaigns is held to the earliest chapter's cap.
    def campaign_chapter = @character.campaigns.pluck(:chapter).compact.min
  end
end
