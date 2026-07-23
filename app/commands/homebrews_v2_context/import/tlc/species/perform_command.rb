# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Species
        # Validates a homebrew TLC species payload and routes to Add (create) or
        # Change (update-by-id). Mirrors Import::Dnd2024::Races::PerformCommand,
        # extended for the TLC "base traits + choose-N optional pool" model
        # (players-guide-digest.md §4/§208): every trait carries `trait_kind`
        # (base|optional) and becomes a Tlc::Feat row (origin 'species') tagged
        # info.trait_kind, so the D2 picker can offer the optional pool while the
        # base traits attach unconditionally.
        class PerformCommand < BaseCommand
          # rubocop: disable Metrics/BlockLength
          use_contract do
            Kinds = Dry::Types['strict.string'].enum('static', 'text', 'update_result', 'hidden')
            Limits = Dry::Types['strict.string'].enum('short_rest', 'long_rest', 'one_at_short_rest')
            TraitKinds = Dry::Types['strict.string'].enum('base', 'optional')
            DamageTypes = Dry::Types['strict.string'].enum(
              'bludge', 'pierce', 'slash', 'acid', 'cold', 'fire', 'force', 'lighting', 'necrotic', 'poison', 'psychic',
              'radiant', 'thunder'
            )
            Sizes = Dry::Types['strict.string'].enum('small', 'medium', 'large')
            CreatureTypes = Dry::Types['strict.string'].enum('humanoid', 'construct')

            params do
              required(:user).filled(type?: ::User)
              optional(:id).filled(:string, :uuid_v4?)
              required(:title).hash do
                required(:en).filled(:string, max_size?: 50)
              end
              required(:description).hash do
                required(:en).filled(:string, max_size?: 500)
              end
              optional(:creature_type).filled(CreatureTypes)
              optional(:interaction_tags).maybe(:array).each(:string)
              optional(:resistance).maybe(:array).each(DamageTypes)
              optional(:immunity).maybe(:array).each(DamageTypes)
              optional(:vulnerability).maybe(:array).each(DamageTypes)
              optional(:size).maybe(:array).each(Sizes)
              optional(:vision).hash do
                optional(:darkvision).maybe(:integer, gteq?: 1, lteq?: 1_000)
                optional(:tremorsense).maybe(:integer, gteq?: 1, lteq?: 1_000)
                optional(:truesight).maybe(:integer, gteq?: 1, lteq?: 1_000)
                optional(:blindsight).maybe(:integer, gteq?: 1, lteq?: 1_000)
              end
              optional(:speed).maybe(:integer, gteq?: 1, lteq?: 100)
              optional(:speeds).hash do
                optional(:flight).maybe(:integer, gteq?: 0, lteq?: 1_000)
                optional(:swim).maybe(:integer, gteq?: 0, lteq?: 1_000)
                optional(:climb).maybe(:integer, gteq?: 0, lteq?: 1_000)
                optional(:burrow).maybe(:integer, gteq?: 0, lteq?: 1_000)
              end
              optional(:optional_pool_size).filled(:integer, gteq?: 0, lteq?: 10)
              optional(:public).filled(:bool)
              optional(:traits).maybe(:array).each(:hash) do
                optional(:id).filled(:string, :uuid_v4?)
                required(:trait_kind).filled(TraitKinds)
                required(:title).hash do
                  required(:en).filled(:string, max_size?: 50)
                end
                required(:description).hash do
                  required(:en).filled(:string, max_size?: 1_000)
                end
                required(:kind).filled(Kinds)
                optional(:limit).filled(:integer, gteq?: 0, lteq?: 20)
                optional(:limit_refresh).filled(Limits)
                optional(:modifiers).hash
                optional(:continious).filled(:bool)
                optional(:level).filled(:integer, gteq?: 1, lteq?: 20)
                optional(:static_spells).hash
                optional(:is_lineage).filled(:bool)
                optional(:lineage_options).array(:hash)
                optional(:grants_free_trait).filled(:string)
                optional(:unlock).filled(:string)
              end
            end
          end
          # rubocop: enable Metrics/BlockLength

          INFO_KEYS = %i[
            creature_type interaction_tags resistance immunity vulnerability size vision speed speeds optional_pool_size
          ].freeze

          private

          def validate_content(input)
            return unless input.key?(:id)

            input[:species] = ::Tlc::Homebrews::Species.find_by(user_id: input[:user].id, id: input[:id])
            return if input[:species]

            ['Not found']
          end

          def do_prepare(input)
            input[:title].transform_values! { |value| sanitize(value) }
            input[:description].transform_values! { |value| sanitize(value) }
            input[:info] = input.slice(*INFO_KEYS)
          end

          def do_persist(input)
            command =
              if input[:species]
                HomebrewsV2Context::Import::Tlc::Species::ChangeCommand.new
              else
                HomebrewsV2Context::Import::Tlc::Species::AddCommand.new
              end
            command.call(input)
          end
        end
      end
    end
  end
end
