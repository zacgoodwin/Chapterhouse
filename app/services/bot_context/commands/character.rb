# frozen_string_literal: true

module BotContext
  module Commands
    class Character
      def call(arguments:, data:)
        return if data[:user].nil?

        case arguments.shift
        when 'list' then fetch_characters(data)
        end
      end

      private

      def fetch_characters(data)
        {
          type: 'list',
          result: data[:user].characters.pluck(:name),
          errors: nil
        }
      end
    end
  end
end
