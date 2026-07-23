# frozen_string_literal: true

module Dnd2024
  class Character
    class Feature < ApplicationRecord
      self.table_name = :dnd2024_character_features

      SPECIES_ORIGIN = 'species'
      CLASS_ORIGIN = 'class'
      LEGACY_ORIGIN = 'legacy'
      SUBCLASS_ORIGIN = 'subclass'
      FEAT_ORIGIN = 'feat'

      # STATIC = 'static'
      # TEXT = 'text'
      # ONE_FROM_LIST = 'one_from_list' # renders a list, one value is selected
      # MANY_FROM_LIST = 'many_from_list' # renders a list, multiple values are selected
      # UPDATE_RESULT = 'update_result' # not rendered, updates decorator data

      STATIC = 'static' # renders text
      STATIC_LIST = 'static_list' # renders a list, one value is selected
      DYNAMIC_LIST = 'dynamic_list' # renders a list, multiple values are selected
      CHOOSE_FROM = 'choose_from' # renders a dynamic list, multiple values are selected
      CHOOSE_ONE_FROM = 'choose_one_from' # renders a dynamic list, one value is selected
      TEXT = 'text' # renders text, text is entered
      UPDATE_RESULT = 'update_result' # not rendered, updates decorator data

      SHORT_REST = 'short_rest'
      LONG_REST = 'long_rest'
      ONE_AT_SHORT_REST = 'one_at_short_rest' # 1 charge is restored on a short rest

      enum :origin, { SPECIES_ORIGIN => 0, CLASS_ORIGIN => 1, LEGACY_ORIGIN => 2, SUBCLASS_ORIGIN => 3, FEAT_ORIGIN => 4 }
      enum :kind, {
        STATIC => 0, STATIC_LIST => 1, DYNAMIC_LIST => 2, CHOOSE_FROM => 3, TEXT => 4, UPDATE_RESULT => 5, CHOOSE_ONE_FROM => 6
      }
      enum :limit_refresh, { SHORT_REST => 0, LONG_REST => 1, ONE_AT_SHORT_REST => 2 }
    end
  end
end
