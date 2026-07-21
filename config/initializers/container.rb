# frozen_string_literal: true

require 'dry/auto_inject'
require 'dry/container'

module Charkeeper
  class Container
    extend Dry::Container::Mixin

    DEFAULT_OPTIONS = { memoize: true }.freeze

    class << self
      def register(key)
        super(key, DEFAULT_OPTIONS)
      end
    end

    register('cache.avatars') { Cache::Avatars.new }
    register('cache.dnd_names') { Cache::DndNames.new }
    register('feature_requirement') { FeatureRequirement.new }
    register('markdown') { ActiveMarkdown.new }
    register('to_bool') { ToBool.new }
    register('roll') { Roll.new }
    register('formula') { Formula.new }
    register('monitoring.providers.rails') { Monitoring::Providers::Rails.new }
    register('monitoring.client') { Monitoring::Client.new }
    register('api.imgproxy.client') { ImgproxyApi::Client.new }
    register('api.discord.client') { DiscordApi::Client.new }
    register('api.supabase.client') { SupabaseApi::Client.new }

    # commands
    register('commands.homebrew_context.dnd.add_item') { HomebrewContext::Dnd::Items::AddCommand.new }

    register('commands.auth_context.add_user') { AuthContext::AddUserCommand.new }
    register('services.auth_context.verify_supabase_token') { AuthContext::VerifySupabaseTokenService.new }
    register('commands.users_context.update') { UsersContext::UpdateCommand.new }
    register('commands.users_context.add_feedback') { UsersContext::AddFeedbackCommand.new }

    register('commands.bonuses_context.refresh') { BonusesContext::RefreshBonusesCommand.new }
    register('commands.bonuses_context.change') { BonusesContext::ChangeCommand.new }
    register('commands.bonuses_context.consume') { BonusesContext::ConsumeCommand.new }

    register('commands.characters_context.items.update') { CharactersContext::Items::UpdateCommand.new }
    register('commands.characters_context.items.add') { CharactersContext::Items::AddCommand.new }
    register('commands.characters_context.items.consume') { CharactersContext::Items::ConsumeCommand.new }
    register('commands.characters_context.change_feat') { CharactersContext::ChangeFeatCommand.new }

    register('commands.characters_context.dnd5.create') { CharactersContext::Dnd5::CreateCommand.new }
    register('commands.characters_context.dnd5.update') { CharactersContext::Dnd5::UpdateCommand.new }
    register('commands.characters_context.dnd5.spell_update') { CharactersContext::Dnd5::SpellUpdateCommand.new }
    register('commands.characters_context.dnd5.spell_add') { CharactersContext::Dnd5::SpellAddCommand.new }
    register('commands.characters_context.dnd5.make_short_rest') { CharactersContext::Dnd5::MakeShortRestCommand.new }
    register('commands.characters_context.dnd5.make_long_rest') { CharactersContext::Dnd5::MakeLongRestCommand.new }
    register('commands.characters_context.dnd5.change_health') { CharactersContext::Dnd5::ChangeHealthCommand.new }
    register('commands.characters_context.dnd5.add_bonus') { CharactersContext::Dnd5::AddBonusCommand.new }

    register('commands.notes_context.add') { NotesContext::AddCommand.new }
    register('commands.notes_context.change') { NotesContext::ChangeCommand.new }

    register('commands.characters_context.dnd2024.create') { CharactersContext::Dnd2024::CreateCommand.new }
    register('commands.characters_context.dnd2024.update') { CharactersContext::Dnd2024::UpdateCommand.new }

    register('commands.characters_context.tlc.create') { CharactersContext::Tlc::CreateCommand.new }
    register('commands.characters_context.tlc.update') { CharactersContext::Tlc::UpdateCommand.new }
    register('commands.characters_context.tlc.make_short_rest') { CharactersContext::Tlc::MakeShortRestCommand.new }
    register('commands.characters_context.tlc.make_long_rest') { CharactersContext::Tlc::MakeLongRestCommand.new }
    register('commands.characters_context.dnd2024.make_short_rest') { CharactersContext::Dnd2024::MakeShortRestCommand.new }
    register('commands.characters_context.dnd2024.make_long_rest') { CharactersContext::Dnd2024::MakeLongRestCommand.new }
    register('commands.characters_context.dnd2024.craft') { CharactersContext::Dnd2024::CraftCommand.new }

    register('commands.characters_context.dnd2024.spells.change') { CharactersContext::Dnd2024::Spells::ChangeCommand.new }
    register('commands.characters_context.dnd2024.spells.add') { CharactersContext::Dnd2024::Spells::AddCommand.new }

    register('commands.characters_context.dnd2024.talents.add') { CharactersContext::Dnd2024::Talents::AddCommand.new }

    register('commands.characters_context.dnd2024.bonuses.add') { CharactersContext::Dnd2024::Bonuses::AddCommand.new }
    register('commands.characters_context.dnd2024.bonuses.add_v3') { CharactersContext::Dnd2024::Bonuses::AddV3Command.new }

    register('commands.characters_context.dnd2024.homebrew.add_item') {
      CharactersContext::Dnd2024::Homebrew::AddItemCommand.new
    }
    register('commands.characters_context.dnd2024.upgrade.perform') {
      CharactersContext::Dnd2024::Upgrade::PerformCommand.new
    }

    register('commands.image_processing.attach_avatar_by_file') { ImageProcessingContext::AttachAvatarByFileCommand.new }
    register('commands.image_processing.attach_avatar_by_url') { ImageProcessingContext::AttachAvatarByUrlCommand.new }

    register('commands.homebrew_context.books.add') { HomebrewContext::Books::AddCommand.new }
    register('commands.homebrew_context.books.change') { HomebrewContext::Books::ChangeCommand.new }

    register('commands.homebrews_v2_context.publications.create') { HomebrewsV2Context::Publications::CreateCommand.new }

    register('commands.campaigns_context.add_campaign') { CampaignsContext::AddCampaignCommand.new }
    register('commands.campaigns_context.join_campaign') { CampaignsContext::JoinCampaignCommand.new }
    register('commands.campaigns_context.remove_campaign') { CampaignsContext::RemoveCampaignCommand.new }

    register('commands.campaigns_context.items.add') { CampaignsContext::Items::AddCommand.new }
    register('commands.campaigns_context.items.change') { CampaignsContext::Items::ChangeCommand.new }
    register('commands.campaigns_context.items.send') { CampaignsContext::Items::SendCommand.new }

    register('commands.channels_context.add_channel') { ChannelsContext::AddChannelCommand.new }

    register('commands.resources_context.add') { ResourcesContext::AddCommand.new }
    register('commands.resources_context.change') { ResourcesContext::ChangeCommand.new }
    register('commands.resources_context.attach') { ResourcesContext::AttachCommand.new }
    register('commands.resources_context.refresh') { ResourcesContext::RefreshCommand.new }

    # services
    register('services.characters_context.dnd5.refresh_feats') { CharactersContext::Dnd5::RefreshFeats.new }
    register('services.characters_context.dnd2024.refresh_feats') { CharactersContext::Dnd2024::RefreshFeats.new }
    register('services.characters_context.tlc.refresh_feats') { CharactersContext::Tlc::RefreshFeats.new }
    register('services.characters_context.tlc.refresh_resources') { CharactersContext::Tlc::RefreshResources.new }

    register('services.bot_context.handle') { BotContext::HandleService.new }

    register('services.bot_context.handle_command') { BotContext::HandleCommandService.new }
    register('services.bot_context.commands.roll') { BotContext::Commands::Roll.new }
    register('services.bot_context.commands.check') { BotContext::Commands::Check.new }
    register('services.bot_context.commands.campaign') { BotContext::Commands::Campaign.new }
    register('services.bot_context.commands.character') { BotContext::Commands::Character.new }

    register('services.bot_context.represent_command') { BotContext::RepresentCommandService.new }

    register('services.homebrews_context.refresh_user_data') { HomebrewsContext::RefreshUserDataService.new }

    register('services.bot_context_v2.character_bot') { BotContextV2::CharacterBot.new }
    register('services.bot_context_v2.represent_character_bot') { BotContextV2::RepresentCharacterBot.new }

    register('services.bot_context_v2.handle_command') { BotContextV2::HandleCommandService.new }

    register('services.bot_context_v2.commands.check') { BotContextV2::Commands::Check.new }

    register('services.bot_context_v2.commands.rolls.default') { BotContextV2::Commands::Rolls::Default.new }
  end
end

Deps = Dry::AutoInject(Charkeeper::Container)
