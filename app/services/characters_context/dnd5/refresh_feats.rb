# frozen_string_literal: true

module CharactersContext
  module Dnd5
    class RefreshFeats < CharactersContext::RefreshFeats
      include CharactersContext::FeatFiltering

      REQUIRED_ATTRIBUTES = %i[id slug conditions origin origin_value limit_refresh exclude tokens].freeze

      private

      # dnd5 feats gate on an array of `selected_feats` and have no species origin.
      def selected_feats_condition_key = 'selected_feats'

      def exclude_origins_from_remove
        ::Dnd5::Feat::SELECTABLE_ORIGINS
      end

      def match_by_level?(condition, item, character, subclasses_levels)
        return true unless condition
        return false if item.origin == 'subclass' && subclasses_levels[item.origin_value] < condition
        return false if item.origin == 'class' && character.data.classes[item.origin_value] < condition

        true
      end

      def match_by_selected_feats?(condition, selected_feats)
        return true unless condition
        return false if (condition - selected_feats).any?

        true
      end

      def find_selected_feats(character)
        character.data.selected_feats.values.flatten
      end

      def feats(character)
        data = character.data
        ::Dnd5::Feat.where(
          origin_value: [data.race, data.subrace, data.classes.keys, data.subclasses.values, character.id].flatten.compact.uniq
        ).or(::Dnd5::Feat.where(origin: 'class', origin_value: 'all'))
      end
    end
  end
end
