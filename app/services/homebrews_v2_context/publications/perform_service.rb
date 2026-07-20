# frozen_string_literal: true

module HomebrewsV2Context
  module Publications
    class PerformService
      def call(publication:) # rubocop: disable Metrics/AbcSize
        errors = {}
        JSON.parse(publication.file.download).each_with_index do |object, index|
          result = command_object(publication).call(object.symbolize_keys.merge({ user: publication.user }))
          errors[index.to_s] = result[:errors] if result[:errors]
        end
        publication.update!(errors_list: errors, completed_at: DateTime.now)
      rescue JSON::ParserError => e
        publication.update!(errors_list: { '0' => { general: [e.message] } }, completed_at: DateTime.now)
      ensure
        publication.file.purge if publication.file.attached?
      end

      private

      def command_object(publication)
        @command_object ||= dnd2024_commands(publication)
      end

      def dnd2024_commands(publication)
        case publication.parent_type
        when 'feat' then HomebrewsV2Context::Import::Dnd2024::Feats::AddCommand.new
        when 'background' then HomebrewsV2Context::Import::Dnd2024::Backgrounds::AddCommand.new
        when 'spell' then HomebrewsV2Context::Import::Dnd2024::Spells::AddCommand.new
        when 'race' then HomebrewsV2Context::Import::Dnd2024::Races::PerformCommand.new
        when 'subclass' then HomebrewsV2Context::Import::Dnd2024::Subclasses::PerformCommand.new
        end
      end
    end
  end
end
