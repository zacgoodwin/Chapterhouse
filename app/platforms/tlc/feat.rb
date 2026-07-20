# frozen_string_literal: true

module Tlc
  # STI subclass mirroring Dnd2024::Feat (TLC is a D&D 2024 variant). Enums are
  # class-level, so each STI sibling must redeclare them. The `session`
  # limit_refresh value is owned by C1 and deliberately not added here.
  class Feat < Feat
    include Tlc::ContentFlags

    tlc_content meta: :info, name: :title

    SPECIES_ORIGIN = 'species'
    LEGACY_ORIGIN = 'legacy'
    CLASS_ORIGIN = 'class'
    SUBCLASS_ORIGIN = 'subclass'
    FEAT_ORIGIN = 'feat'
    CHARACTER_ORIGIN = 'character'
    SPELL_ORIGIN = 'spell'

    STATIC = 'static'
    TEXT = 'text'
    UPDATE_RESULT = 'update_result'
    ONE_FROM_LIST = 'one_from_list'
    MANY_FROM_LIST = 'many_from_list'
    HIDDEN = 'hidden'

    SHORT_REST = 'short_rest'
    LONG_REST = 'long_rest'
    ONE_AT_SHORT_REST = 'one_at_short_rest'

    SELECTABLE_ORIGINS = [4, 5, 6].freeze

    enum :origin, {
      SPECIES_ORIGIN => 0, CLASS_ORIGIN => 1, LEGACY_ORIGIN => 2, SUBCLASS_ORIGIN => 3, FEAT_ORIGIN => 4, CHARACTER_ORIGIN => 5,
      SPELL_ORIGIN => 6
    }
    enum :kind, {
      STATIC => 0, TEXT => 1, UPDATE_RESULT => 2, ONE_FROM_LIST => 3, MANY_FROM_LIST => 4, HIDDEN => 5
    }
    enum :limit_refresh, { SHORT_REST => 0, LONG_REST => 1, ONE_AT_SHORT_REST => 2 }
  end
end
