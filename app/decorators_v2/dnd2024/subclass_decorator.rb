# frozen_string_literal: true

module Dnd2024
  class SubclassDecorator < ApplicationDecoratorV2
    SPELL_SLOTS = SpellSlots::FULL_CASTER

    def call(result:)
      subclass_keys = result['subclasses'].values.compact
      subclass_keys.each { |subclass_name| result = subclass_decorator(subclass_name, result) }

      result['spells_slots'] = select_spells_slots(result)
      result['available_spell_level'] = result['spells_slots'].keys.max
      result
    end

    private

    def select_spells_slots(result)
      if result['spell_classes'].values.many? { |value| value[:save_dc].present? }
        multiclass_level = [result['spell_classes'].values.pluck(:multiclass_spell_level).compact.sum, 20].min
        SPELL_SLOTS[multiclass_level]
      else
        result['spells_slots']
      end
    end

    def subclass_decorator(subclass_name, result)
      "Dnd2024::Subclasses::#{subclass_name.camelize}Decorator".constantize.new.call(result: result)
    rescue NameError => _e
      result
    end
  end
end
