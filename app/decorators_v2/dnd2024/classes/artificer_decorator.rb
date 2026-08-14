# frozen_string_literal: true

module Dnd2024
  module Classes
    class ArtificerDecorator < ApplicationDecoratorV2
      SPELL_SLOTS = SpellSlots::HALF_CASTER
      CLASS_SAVE_DC = %w[con int].freeze

      def call(result:)
        @result = result
        @result['class_save_dc'] = CLASS_SAVE_DC if main_class == 'artificer'
        @result['spell_classes']['artificer'] = spell_class_info
        @result['spells_slots'] = SPELL_SLOTS[class_level] || SPELL_SLOTS[20]
        @result
      end

      private

      def spell_class_info
        {
          save_dc: 8 + proficiency_bonus + modifiers['int'],
          attack_bonus: proficiency_bonus + modifiers['int'],
          cantrips_amount: cantrips_amount,
          max_spell_level: max_spell_level,
          prepared_spells_amount: prepared_spells_amount,
          multiclass_spell_level: (class_level / 2.0).round # half round up
        }
      end

      def class_level
        @class_level ||= classes['artificer']
      end

      def cantrips_amount
        return 4 if class_level >= 14
        return 3 if class_level >= 10

        2
      end

      def prepared_spells_amount # rubocop: disable Metrics/PerceivedComplexity
        return 15 if class_level >= 19
        return 14 if class_level >= 17
        return 12 if class_level >= 15
        return 11 if class_level >= 13
        return 10 if class_level >= 11
        return 9 if class_level >= 9
        return 7 if class_level >= 8
        return class_level if class_level >= 6

        class_level + 1
      end

      def max_spell_level
        SPELL_SLOTS[class_level].keys.max
      end
    end
  end
end
