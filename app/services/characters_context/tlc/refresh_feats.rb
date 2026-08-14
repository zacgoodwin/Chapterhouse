# frozen_string_literal: true

module CharactersContext
  module Tlc
    class RefreshFeats < CharactersContext::RefreshFeats
      include CharactersContext::FeatFiltering

      # `type` is REQUIRED here: feats() unions on the base Feat class (tlc_content),
      # so a select() that omits `type` cannot resolve STI and instantiates rows as
      # base `Feat` -- whose `origin`/`limit_refresh` enums are undeclared, raising
      # NoMethodError downstream in add_new_available_feats (proven in #11). The
      # dnd2024 sibling can omit it only because it queries the concrete ::Dnd2024::Feat.
      REQUIRED_ATTRIBUTES = %i[id slug conditions origin origin_value limit_refresh exclude tokens type].freeze

      private

      def exclude_origins_from_remove
        ::Tlc::Feat::SELECTABLE_ORIGINS
      end

      def feats(character)
        data = character.data
        # Shared-content union -- the same scope the spells path uses at
        # tlc/create_command.rb:110. Shared species/class features live as
        # Dnd2024::Feat rows, so the strict ::Tlc::Feat scope attaches nothing (#76).
        # Same-slug TLC-over-2024 precedence is #21's shadow clause folded INTO
        # scope :tlc_content, so this call site inherits it when #21 lands -- do not
        # duplicate the shadow here.
        ::Feat.tlc_content.where(
          origin_value: [data.species, data.legacy, data.classes.keys, data.subclasses.values, character.id].flatten.compact.uniq
        )
      end
    end
  end
end
