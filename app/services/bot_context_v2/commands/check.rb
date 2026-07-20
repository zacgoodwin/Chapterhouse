# frozen_string_literal: true

module BotContextV2
  module Commands
    class Check
      def call(arguments:, character:)
        service(character).call(arguments: arguments)
      end

      private

      def service(character)
        case character.class.name
        when 'Dnd5::Character', 'Dnd2024::Character'
          BotContextV2::Commands::Checks::Dnd.new
        end
      end
    end
  end
end
