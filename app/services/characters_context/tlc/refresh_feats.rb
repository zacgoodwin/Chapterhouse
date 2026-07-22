# frozen_string_literal: true

module CharactersContext
  module Tlc
    class RefreshFeats < CharactersContext::RefreshFeats
      # `type` is REQUIRED here: feats() unions on the base Feat class (tlc_content),
      # so a select() that omits `type` cannot resolve STI and instantiates rows as
      # base `Feat` -- whose `origin`/`limit_refresh` enums are undeclared, raising
      # NoMethodError downstream in add_new_available_feats (proven in #11). The
      # dnd2024 sibling can omit it only because it queries the concrete ::Dnd2024::Feat.
      REQUIRED_ATTRIBUTES = %i[id slug conditions origin origin_value limit_refresh exclude tokens type].freeze

      private

      def remove_redundant_feats(...); end

      def exclude_origins_from_remove
        ::Tlc::Feat::SELECTABLE_ORIGINS
      end

      def filter_available_feats(character)
        selected_feats = find_selected_feats(character)
        subclasses_levels = find_subclasses_levels(character)

        feats(character).select(*REQUIRED_ATTRIBUTES).filter_map do |item|
          next item if item.conditions.blank?

          filter_feat(item, character, subclasses_levels, selected_feats)
        end
      end

      def filter_feat(item, character, subclasses_levels, selected_feats)
        conditions = item.conditions
        return unless match_by_level?(conditions['level'], item, character, subclasses_levels)
        return unless match_by_selected_feats?(conditions['selected_feature'], selected_feats)

        item
      end

      def match_by_level?(condition, item, character, subclasses_levels)
        return true unless condition
        return false if item.origin == 'subclass' && subclasses_levels[item.origin_value] < condition
        return false if item.origin == 'class' && character.data.classes[item.origin_value] < condition
        return false if item.origin == 'species' && character.data.level < condition

        true
      end

      def match_by_selected_feats?(condition, selected_feats)
        return true unless condition
        return false if ([condition] - selected_feats).any?

        true
      end

      def find_selected_feats(character)
        character.data.selected_features.values.flatten
      end

      def find_subclasses_levels(character)
        character.data.subclasses.to_h { |key, value| [value, character.data.classes[key]] }
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
