# frozen_string_literal: true

module Dnd5Character
  module Classes
    class ArtificerDecorator < ApplicationDecorator
      SPELL_SLOTS = SpellSlots::HALF_CASTER
      CLASS_SAVE_DC = %w[con int].freeze

      def class_save_dc
        @class_save_dc ||= main_class == 'artificer' ? CLASS_SAVE_DC : __getobj__.class_save_dc
      end

      # rubocop: disable Metrics/AbcSize
      def spell_classes
        @spell_classes ||= begin
          result = __getobj__.spell_classes
          result[:artificer] = {
            save_dc: 8 + proficiency_bonus + modifiers['int'],
            attack_bonus: proficiency_bonus + modifiers['int'],
            cantrips_amount: cantrips_amount,
            max_spell_level: max_spell_level,
            prepared_spells_amount: [modifiers['int'] + (class_level / 2), 1].max,
            multiclass_spell_level: (class_level / 2.0).round # half round up
          }
          result
        end
      end
      # rubocop: enable Metrics/AbcSize

      def spells_slots
        @spells_slots ||= SPELL_SLOTS[class_level]
      end

      private

      def class_level
        @class_level ||= classes['artificer']
      end

      def cantrips_amount
        return 4 if class_level >= 14
        return 3 if class_level >= 10

        2
      end

      def max_spell_level
        SPELL_SLOTS[class_level].keys.max
      end
    end
  end
end
