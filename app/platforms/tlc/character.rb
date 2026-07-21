# frozen_string_literal: true

module Tlc
  # Field-by-field parity with Dnd2024::CharacterData (TLC is a D&D 2024 variant),
  # plus five TLC-specific fields. The parity block below must stay a superset of
  # Dnd2024::CharacterData — spec/platforms/tlc/character_spec.rb fails loudly if it drifts.
  class CharacterData
    include StoreModel::Model

    # --- Dnd2024::CharacterData parity (keep in sync) ---
    attribute :level, :integer, default: 1
    attribute :species, :string
    attribute :legacy, :string
    attribute :background, :string
    attribute :size, :string, default: 'medium'
    attribute :alignment, :string
    attribute :main_class, :string
    attribute :classes, array: true
    attribute :subclasses, array: true
    attribute :abilities, array: true, default: { 'str' => 10, 'dex' => 10, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 10 }
    attribute :health, array: true
    attribute :death_saving_throws, array: true, default: { 'success' => 0, 'failure' => 0 }
    attribute :speed, :integer, default: 30
    attribute :speeds, array: true, default: {}
    attribute :darkvision, :integer, default: 0
    attribute :selected_skills, array: true, default: {}
    attribute :selected_features, array: true, default: {}
    attribute :selected_feats, array: true, default: []
    attribute :languages, array: true, default: []
    attribute :weapon_core_skills, array: true
    attribute :weapon_skills, array: true
    attribute :weapon_mastery, array: true, default: []
    attribute :armor_proficiency, array: true
    attribute :coins, array: true, default: { 'gold' => 0, 'silver' => 0, 'copper' => 0 }
    attribute :money, :integer, default: 0
    attribute :spent_spell_slots, array: true, default: {}
    attribute :hit_dice, array: true, default: {}
    attribute :spent_hit_dice, array: true, default: {}
    attribute :tools, array: true, default: []
    attribute :music, array: true, default: []
    attribute :resistance, array: true, default: []
    attribute :immunity, array: true, default: []
    attribute :vulnerability, array: true, default: []
    attribute :selected_beastforms, array: true, default: []
    attribute :beastform, :string
    attribute :conditions, array: true, default: []
    attribute :heroic_inspiration, :boolean, default: false
    attribute :bardic_inspiration, :integer
    attribute :selected_talents, array: true, default: {}
    attribute :selected_additional_talents, array: true, default: 0
    attribute :exhaustion, :integer, default: 0
    attribute :guide_step, :integer
    attribute :ability_boosts, array: true, default: []
    attribute :any_skill_boosts, :integer, default: 0
    attribute :skill_boosts, :integer, default: 0
    attribute :skill_boosts_list, array: true, default: []
    attribute :leveling_ability_boosts, :integer, default: 0
    attribute :leveling_ability_boosts_list, array: true, default: []

    # --- TLC-specific fields ---
    attribute :leyfarer_rank, :integer, default: 0
    attribute :leyfarer_focus, :string
    attribute :selected_traits, array: true, default: []
    attribute :mixed_species, :string
    attribute :dismissed_warnings, array: true, default: []
  end

  class Character < Character
    def self.config
      @config ||= PlatformConfig.data('tlc')
    end

    attribute :data, Tlc::CharacterData.to_type

    # TlcDecorator is added by A4; this forward reference resolves at call time.
    def decorator(simple: false, version: nil)
      TlcDecorator.new.call(character: self, simple: simple, exclude_feature_origins: [6], version: version)
    end

    # Display names for the serializer's `names` field. They read the dnd2024
    # baseline config because TLC ships no distinct species/background config
    # (plan P4). Homebrew name resolution through the dnd2024-keyed
    # `cache.dnd_names` stays parked to Phase D, so an unknown slug renders '-',
    # the same value Dnd2024::Character#species_name lands on with no cache hit.
    # Copying that fallback here would be dead code today: the TLC importer
    # deliberately writes nothing to dnd_names
    # (homebrews_v2_context/import/tlc/species/add_command.rb:11), so the lookup
    # can only miss until Phase D adds a TLC-keyed name cache.
    def species_name = config_name(::Dnd2024::Character.species, data.species)

    def background_name = config_name(::Dnd2024::Character.backgrounds, data.background)

    private

    def config_name(config, slug)
      return '' if slug.blank?

      entry = config[slug]
      entry ? translate(entry['name']) : '-'
    end
  end
end
