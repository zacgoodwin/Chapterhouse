# frozen_string_literal: true

module TlcCharacter
  class ClassBuilder
    def call(result:)
      result = class_builder(result[:main_class]).call(result: result)
      result[:hit_dice][::Dnd2024::Character::HIT_DICES[result[:main_class]]] = result[:classes][result[:main_class]]
      result
    end

    private

    def class_builder(main_class)
      "TlcCharacter::Classes::#{main_class.camelize}Builder".constantize.new
    rescue NameError => _e
      DummyBuilder.new
    end
  end
end
