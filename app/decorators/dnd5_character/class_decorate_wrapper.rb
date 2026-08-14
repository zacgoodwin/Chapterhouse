# frozen_string_literal: true

module Dnd5Character
  class ClassDecorateWrapper < ApplicationDecorateWrapper
    SPELL_SLOTS = SpellSlots::FULL_CASTER

    def spells_slots
      @spells_slots ||=
        if spell_classes.values.many? { |value| value[:save_dc].present? }
          multiclass_level = [spell_classes.values.pluck(:multiclass_spell_level).compact.sum, 20].min
          SPELL_SLOTS[multiclass_level]
        else
          wrapped.spells_slots
        end
    end

    def available_spell_level
      spells_slots.keys.max
    end

    private

    def wrap_classes(obj)
      obj.classes.keys.inject(obj) do |acc, class_name|
        acc = class_decorator(class_name).new(acc)
        acc
      end
    end

    def class_decorator(class_name)
      "Dnd5Character::Classes::#{class_name.camelize}Decorator".constantize
    end
  end
end
