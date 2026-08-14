# frozen_string_literal: true

module CharactersContext
  module Dnd2024
    class RefreshFeats < CharactersContext::RefreshFeats
      include CharactersContext::FeatFiltering

      REQUIRED_ATTRIBUTES = %i[id slug conditions origin origin_value limit_refresh exclude tokens].freeze

      private

      def exclude_origins_from_remove
        ::Dnd2024::Feat::SELECTABLE_ORIGINS
      end

      def feats(character)
        data = character.data
        ::Dnd2024::Feat.where(
          origin_value: [data.species, data.legacy, data.classes.keys, data.subclasses.values, character.id].flatten.compact.uniq
        )
      end
    end
  end
end
