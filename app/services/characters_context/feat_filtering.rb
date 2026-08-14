# frozen_string_literal: true

module CharactersContext
  # Level/selection gating of the feat rows a character qualifies for, shared by
  # every provider's RefreshFeats. Defaults follow the D&D 2024 rules (feats
  # gated by `selected_feature` and species level); dnd5 overrides the three
  # predicates that read its older feat shape. Including classes must supply
  # `feats` (the content scope) and a `REQUIRED_ATTRIBUTES` list.
  module FeatFiltering
    private

    def feats(_character) = raise(NotImplementedError)
    def selected_feats_condition_key = 'selected_feature'
    def remove_redundant_feats(...); end

    def filter_available_feats(character)
      selected_feats = find_selected_feats(character)
      subclasses_levels = find_subclasses_levels(character)

      feats(character).select(*self.class::REQUIRED_ATTRIBUTES).filter_map do |item|
        next item if item.conditions.blank?

        filter_feat(item, character, subclasses_levels, selected_feats)
      end
    end

    def filter_feat(item, character, subclasses_levels, selected_feats)
      conditions = item.conditions
      return unless match_by_level?(conditions['level'], item, character, subclasses_levels)
      return unless match_by_selected_feats?(conditions[selected_feats_condition_key], selected_feats)

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
  end
end
