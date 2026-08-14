# frozen_string_literal: true

module Dnd2024
  module Subclasses
    # Third-caster progression shared by Arcane Trickster (rogue) and Eldritch
    # Knight (fighter): same slots, same Intelligence-based DCs, same prepared
    # spell counts. Subclasses only name the class the spellcasting hangs off.
    class ThirdCasterDecorator < ApplicationDecoratorV2
      SPELL_SLOTS = SpellSlots::THIRD_CASTER

      def call(result:)
        @result = result
        @result['spell_classes'][spellcasting_class] = spell_class_info
        @result['spells_slots'] = SPELL_SLOTS[class_level] || SPELL_SLOTS[20]
        @result
      end

      private

      def spellcasting_class = raise(NotImplementedError)

      def spell_class_info
        {
          save_dc: 8 + proficiency_bonus + modifiers['int'],
          attack_bonus: proficiency_bonus + modifiers['int'],
          cantrips_amount: cantrips_amount,
          max_spell_level: max_spell_level,
          prepared_spells_amount: prepared_spells_amount,
          multiclass_spell_level: class_level / 3
        }
      end

      def class_level
        @class_level ||= classes[spellcasting_class]
      end

      def cantrips_amount
        return 3 if class_level >= 10

        2
      end

      def prepared_spells_amount # rubocop: disable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/CyclomaticComplexity
        return 13 if class_level >= 20
        return 12 if class_level >= 19
        return 11 if class_level >= 16
        return 10 if class_level >= 14
        return 9 if class_level >= 13
        return 8 if class_level >= 11
        return 7 if class_level >= 10
        return 6 if class_level >= 8
        return 5 if class_level >= 7
        return 4 if class_level >= 4

        3
      end

      def max_spell_level
        SPELL_SLOTS[class_level].keys.max
      end
    end
  end
end
