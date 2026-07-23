# frozen_string_literal: true

module Dnd5
  class Character
    class Feature < ApplicationRecord
      self.table_name = :dnd5_character_features

      RACE_ORIGIN = 'race'
      SUBRACE_ORIGIN = 'subrace'
      CLASS_ORIGIN = 'class'
      SUBCLASS_ORIGIN = 'subclass'

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

      enum :origin, { RACE_ORIGIN => 0, SUBRACE_ORIGIN => 1, CLASS_ORIGIN => 2, SUBCLASS_ORIGIN => 3 }
      enum :kind, {
        STATIC => 0, STATIC_LIST => 1, DYNAMIC_LIST => 2, CHOOSE_FROM => 3, TEXT => 4, UPDATE_RESULT => 5, CHOOSE_ONE_FROM => 6
      }
      enum :limit_refresh, { SHORT_REST => 0, LONG_REST => 1 }
    end
  end
end
