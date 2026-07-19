# frozen_string_literal: true

module BotContext
  class HandleService
    include Deps[
      handle_command: 'services.bot_context.handle_command',
      represent_command: 'services.bot_context.represent_command'
    ]

    RESPONSE_SOURCES = %i[web raw].freeze

    def call(source:, message:, data: {})
      command, arguments = parse_command_text(message)

      command_result = handle_command.call(source: source, command: command, arguments: arguments, data: data)
      return response(source, { errors: ['Invalid command'] }) if command_result.nil?
      return response(source, { errors: command_result[:errors] }) if command_result[:errors].present?

      command_formatted_result = represent_command.call(source: source, command: command, command_result: command_result)
      return if command_formatted_result.nil?

      response(source, command_formatted_result)
    rescue ActiveRecord::RecordNotFound => _e
      { errors: [I18n.t('not_found')], errors_list: [I18n.t('not_found')] }
    rescue ArgumentError, OptionParser::MissingArgument => _e
      { errors: ['Invalid command'], errors_list: ['Invalid command'] }
    end

    private

    # rubocop: disable Style/RedundantRegexpArgument
    def parse_command_text(str)
      result = str.scan(/(?:\"(?:\\\"|[^\"])*\"|\'(?:\\\'|[^\'])*\'|[^\s"]+)/).map do |match|
        # Remove surrounding quotes if present and unescape internal quotes
        if match.start_with?('"') && match.end_with?('"')
          match[1..-2].gsub(/\\"/, '"')
        elsif match.start_with?('\'') && match.end_with?('\'')
          match[1..-2].gsub(/\\'/, '\'')
        else
          match
        end
      end
      [result.shift, result]
    end
    # rubocop: enable Style/RedundantRegexpArgument

    def response(source, result)
      { result: result[:result], errors: result[:errors], errors_list: result[:errors] } if source.in?(RESPONSE_SOURCES)
    end
  end
end
