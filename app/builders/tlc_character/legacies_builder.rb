# frozen_string_literal: true

module TlcCharacter
  class LegaciesBuilder
    def call(result:)
      legacy_builder(result[:legacy]).call(result: result)
    end

    private

    def legacy_builder(legacy)
      "TlcCharacter::Legacies::#{legacy.camelize}Builder".constantize.new
    rescue NameError => _e
      DummyBuilder.new
    end
  end
end
