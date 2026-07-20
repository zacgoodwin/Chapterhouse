# frozen_string_literal: true

module BotContext
  module Commands
    class Campaign
      include Deps[
        add_campaign_command: 'commands.campaigns_context.add_campaign',
        remove_campaign_command: 'commands.campaigns_context.remove_campaign'
      ]

      def call(arguments:, data:)
        return if data[:user].nil?

        case arguments.shift
        when 'create' then create_campaign(*arguments, data)
        when 'list' then fetch_campaigns(data)
        when 'remove' then remove_campaign(*arguments, data)
        end
      end

      private

      def create_campaign(*arguments, data)
        values = BotContext::Commands::Parsers::CreateCampaign.new.call(arguments: arguments)
        result = add_campaign_command.call(user: data[:user], name: values[:name], provider: values[:system])

        {
          type: 'create',
          result: result[:result],
          errors: result[:errors_list]
        }
      end

      def fetch_campaigns(data)
        {
          type: 'list',
          result: data[:user].campaigns.hashable_pluck(:name, :provider),
          errors: nil
        }
      end

      def remove_campaign(name, data)
        result = remove_campaign_command.call(user: data[:user], name: name)
        {
          type: 'remove',
          result: result[:result],
          errors: result[:errors_list]
        }
      end
    end
  end
end
