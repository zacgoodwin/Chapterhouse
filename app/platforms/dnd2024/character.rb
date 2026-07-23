# frozen_string_literal: true

module Dnd2024
  class CharacterData
    include StoreModel::Model

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
    attribute :speeds, array: true, default: {} # { 'flight' => 30, 'swim' => 0, 'climb' => 10 }
    attribute :darkvision, :integer, default: 0
    attribute :selected_skills, array: true, default: {} # { 'history' => 1 }
    attribute :selected_features, array: true, default: {} # { 'fighting_style' => ['fighting_style_defense'] }
    attribute :selected_feats, array: true, default: []
    attribute :languages, array: true, default: []
    attribute :weapon_core_skills, array: true
    attribute :weapon_skills, array: true
    attribute :weapon_mastery, array: true, default: [] # weapon masteries
    attribute :armor_proficiency, array: true
    attribute :coins, array: true, default: { 'gold' => 0, 'silver' => 0, 'copper' => 0 }
    attribute :money, :integer, default: 0
    attribute :spent_spell_slots, array: true, default: {}
    attribute :hit_dice, array: true, default: {} # maximum hit dice
    attribute :spent_hit_dice, array: true, default: {} # spent hit dice
    attribute :tools, array: true, default: [] # tool proficiencies
    attribute :music, array: true, default: [] # musical instrument proficiencies
    attribute :resistance, array: true, default: [] # resistances
    attribute :immunity, array: true, default: [] # immunities
    attribute :vulnerability, array: true, default: [] # vulnerabilities
    attribute :selected_beastforms, array: true, default: []
    attribute :beastform, :string
    attribute :conditions, array: true, default: []
    attribute :heroic_inspiration, :boolean, default: false
    attribute :bardic_inspiration, :integer
    attribute :selected_talents, array: true, default: {}
    attribute :selected_additional_talents, array: true, default: 0
    attribute :exhaustion, :integer, default: 0
    # level 1 only
    attribute :guide_step, :integer # character creation guide step
    attribute :ability_boosts, array: true, default: [] # extra ability score increases from background
    attribute :any_skill_boosts, :integer, default: 0 # extra increases for any skill
    attribute :skill_boosts, :integer, default: 0 # extra skill increases from class
    attribute :skill_boosts_list, array: true, default: [] # extra skill increases from class
    attribute :leveling_ability_boosts, :integer, default: 0
    attribute :leveling_ability_boosts_list, array: true, default: []
  end

  class Character < Character
    def self.config
      @config ||= PlatformConfig.data('dnd2024')
    end

    def self.species
      config['species']
    end

    def self.species_info(race_value)
      config.dig('species', race_value)
    end

    def self.sizes_info(race_value)
      config.dig('species', race_value, 'sizes')
    end

    def self.legacies_info(race_value)
      config.dig('species', race_value, 'legacies')
    end

    def self.legacy_info(race_value, legacy_value)
      config.dig('species', race_value, 'legacies', legacy_value)
    end

    def self.classes_info
      config['classes']
    end

    def self.class_info(class_value)
      config.dig('classes', class_value)
    end

    def self.subclasses_info(class_value)
      config.dig('classes', class_value, 'subclasses')
    end

    def self.subclass_info(class_value, subclass_value)
      config.dig('classes', class_value, 'subclasses', subclass_value)
    end

    def self.beastforms
      config['beastforms']
    end

    def self.abilities
      config['abilities']
    end

    def self.skills
      config['skills']
    end

    def self.backgrounds
      config['backgrounds']
    end

    # alignment
    LAWFUL_GOOD = 'lawful_good'
    LAWFUL_NEUTRAL = 'lawful_neutral'
    LAWFUL_EVIL = 'lawful_evil'
    NEUTRAL_GOOD = 'neutral_good'
    NEUTRAL = 'neutral'
    NEUTRAL_EVIL = 'neutral_evil'
    CHAOTIC_GOOD = 'chaotic_good'
    CHAOTIC_NEUTRAL = 'chaotic_neutral'
    CHAOTIC_EVIL = 'chaotic_evil'

    # languages
    # common, dwarvish, elvish, giant, gnomish, goblin, halfling, orc, draconic, undercommon, infernal, druidic
    ALIGNMENTS = [
      LAWFUL_GOOD, LAWFUL_NEUTRAL, LAWFUL_EVIL, NEUTRAL_GOOD, NEUTRAL,
      NEUTRAL_EVIL, CHAOTIC_GOOD, CHAOTIC_NEUTRAL, CHAOTIC_EVIL
    ].freeze
    HIT_DICES = {
      'barbarian' => 12, 'bard' => 8, 'cleric' => 8, 'druid' => 8, 'fighter' => 10, 'monk' => 8,
      'paladin' => 10, 'ranger' => 10, 'rogue' => 8, 'sorcerer' => 6, 'warlock' => 8, 'wizard' => 6, 'artificer' => 8
    }.freeze

    # bard knows all spells, prepares a new one and/or swaps a prepared one on level up
    # warlock knows all spells, prepares a new one and/or swaps a prepared one on level up
    # sorcerer knows all spells, prepares a new one and/or swaps a prepared one on level up

    # cleric knows all spells, swaps prepared ones after a long rest
    # druid knows all spells, swaps prepared ones after a long rest
    # artificer knows all spells, swaps prepared ones after a long rest

    # ranger knows all spells, swaps 1 prepared one after a long rest
    # paladin knows all spells, swaps 1 prepared one after a long rest

    # wizard adds spells to the spellbook on level up
    # wizard swaps prepared spells after a long rest

    # the full class spell list is known immediately (all except wizard)
    CLASSES_KNOW_SPELLS_LIST = %w[bard cleric druid paladin ranger sorcerer warlock artificer].freeze

    attribute :data, Dnd2024::CharacterData.to_type

    def decorator(simple: false, version: nil)
      Dnd2024Decorator.new.call(character: self, simple: simple, exclude_feature_origins: [6], version: version)
    end

    def subclass_names
      data.subclasses.each_with_object({}) do |(class_slug, subclass_slug), acc|
        acc[class_name(class_slug)] = { level: data.classes[class_slug], subclass: subclass_name(class_slug, subclass_slug) }
      end
    end

    def species_name
      return '' unless data.species

      default = ::Dnd2024::Character.species[data.species]
      return translate(default['name']) if default

      custom_name = dnd_names.fetch_item(key: :races, id: data.species)
      custom_name ? translate(custom_name[:name]) : '-'
    end

    def background_name
      return '' unless data.background

      default = ::Dnd2024::Character.backgrounds[data.background]
      return translate(default['name']) if default

      custom_name = dnd_names.fetch_item(key: :backgrounds, id: data.background)
      custom_name ? translate(custom_name[:name]) : '-'
    end

    private

    def class_name(class_slug)
      default = ::Dnd2024::Character.class_info(class_slug)
      return translate(default['name']) if default

      translate(dnd_names.fetch_item(key: :classes, id: class_slug)[:name])
    end

    def subclass_name(class_slug, subclass_slug)
      return unless subclass_slug

      default = ::Dnd2024::Character.subclass_info(class_slug, subclass_slug)
      return translate(default['name']) if default

      translate(dnd_names.fetch_item(key: :subclasses, id: subclass_slug)[:name])
    end

    def dnd_names = Charkeeper::Container.resolve('cache.dnd_names')
  end
end
