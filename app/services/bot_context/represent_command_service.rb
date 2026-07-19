# frozen_string_literal: true

module BotContext
  class RepresentCommandService
    def call(source:, command:, command_result:)
      return command_result if source == :raw

      # app/views/bots/web/homebrew/add_race.text.erb
      template = ERB.new(
        Rails.root.join('app/views/bots', source.to_s, command[1..], "#{command_result[:type]}.text.erb").read
      )
      { result: template.result_with_hash(command_result).strip }
    end
  end
end
