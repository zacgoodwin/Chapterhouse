# frozen_string_literal: true

module BotContextV2
  class HandleCommandService
    include Deps[
      default_roll_command: 'services.bot_context_v2.commands.rolls.default',
      check_command: 'services.bot_context_v2.commands.check'
    ]

    def call(command:, arguments:, character:)
      case command
      when '/roll' then default_roll_command.call(arguments: arguments)
      when '/check' then check_command.call(arguments: arguments, character: character)
      end
    end
  end
end
