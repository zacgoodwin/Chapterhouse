# frozen_string_literal: true

module TlcCharacter
  class BackgroundBuilder
    def call(result:)
      return result if result[:background].blank?

      background_builder(result[:background]).call(result: result)
    end

    private

    def background_builder(background)
      default = ::Dnd2024::Character.backgrounds[background]
      return "TlcCharacter::Backgrounds::#{background.camelize}Builder".constantize.new if default

      TlcCharacter::Backgrounds::CustomBuilder.new
    rescue NameError => _e
      DummyBuilder.new
    end
  end
end
