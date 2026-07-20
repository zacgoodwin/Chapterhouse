# frozen_string_literal: true

module Tlc
  # Homebrew authoring record for a TLC species, mirroring Dnd2024::Homebrews::Race
  # but shaped to the TLC "fixed base traits + choose N from an optional pool"
  # model (players-guide-digest.md §4 / §208). The base-vs-optional split and the
  # lineage sub-options live ON the trait rows (Tlc::Feat, info.trait_kind /
  # info.is_lineage), not here; this record carries only the species-level facts
  # and the pool size the picker enforces. `< ::Homebrew` so it stores in the
  # shared homebrews table and inherits discard/upvote/visibility scoping.
  module Homebrews
    class SpeciesData
      include StoreModel::Model

      # humanoid (default) or construct (Fabricated). Interaction tags widen
      # targeting (wilderfolk/dreamtouched/biomechanical/nephilim/shedim/
      # dragonborn_tag/fiend_tag/monstrosity_tag) — booleans as a string list.
      attribute :creature_type, :string, default: 'humanoid'
      attribute :interaction_tags, array: true, default: []

      # bludge/pierce/slash/acid/cold/fire/force/lighting/necrotic/poison/psychic/radiant/thunder
      attribute :resistance, array: true, default: []
      attribute :immunity, array: true, default: []
      attribute :vulnerability, array: true, default: []
      # Many TLC species choose Small OR Medium at selection, so size is a list.
      attribute :size, array: true, default: ['medium']
      # { 'darkvision' => 60 } / { 'tremorsense' => 30 } (Dwarf swaps darkvision).
      attribute :vision, array: true, default: {}
      attribute :speed, :integer, default: 30
      # { 'flight' => 30 } flight/swim/climb/burrow
      attribute :speeds, array: true, default: {}
      # "choose N" optional traits (3 default; 4 with Mixed Ancestry). The picker
      # (D2) reads this to size the pool; free traits do not count against it.
      attribute :optional_pool_size, :integer, default: 3
    end

    class Species < ::Homebrew
      attribute :info, Tlc::Homebrews::SpeciesData.to_type

      def to_homebrew_json(with_id: true) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
        [
          {
            id: with_id ? id : nil,
            title: title,
            description: description,
            public: attributes['public'],
            creature_type: info.creature_type,
            interaction_tags: info.interaction_tags,
            resistance: info.resistance,
            immunity: info.immunity,
            vulnerability: info.vulnerability,
            size: info.size,
            vision: info.vision,
            speed: info.speed,
            speeds: info.speeds,
            optional_pool_size: info.optional_pool_size,
            features: ::Tlc::Feat.where(origin: 'species', origin_value: id).map { |item|
              item.to_homebrew_json(with_id: with_id)
            }
          }.compact
        ]
      end
    end
  end
end
