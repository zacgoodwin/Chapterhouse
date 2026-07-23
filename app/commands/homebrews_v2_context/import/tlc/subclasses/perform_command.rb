# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Subclasses
        # Validates a homebrew TLC subclass payload and routes to Add/Change.
        # Mirrors Import::Dnd2024::Subclasses::PerformCommand, plus a `resources`
        # array of C8-shaped pool definitions (db/data/tlc/resources.json schema)
        # that CharactersContext::Tlc::RefreshResources instantiates once the
        # subclass is attached to a character. `max_formula` is a Dentaku string
        # (sandboxed by app/lib/formula.rb), NOT a Ruby-eval field, so it is safe
        # to accept from homebrew input.
        class PerformCommand < BaseCommand
          # rubocop: disable Metrics/BlockLength
          use_contract do
            Kinds = Dry::Types['strict.string'].enum('static', 'text', 'update_result', 'hidden')
            Limits = Dry::Types['strict.string'].enum('short_rest', 'long_rest', 'one_at_short_rest')

            params do
              required(:user).filled(type?: ::User)
              optional(:id).filled(:string, :uuid_v4?)
              required(:title).hash do
                required(:en).filled(:string, max_size?: 50)
              end
              required(:description).hash do
                required(:en).filled(:string, max_size?: 500)
              end
              required(:class_id).filled(:string)
              optional(:public).filled(:bool)
              optional(:resources).maybe(:array).each(:hash) do
                required(:slug).filled(:string, max_size?: 50)
                required(:name).filled(:string, max_size?: 50)
                optional(:description).maybe(:string, max_size?: 1_000)
                optional(:min_class_level).filled(:integer, gteq?: 1, lteq?: 20)
                optional(:max_formula).maybe(:string, max_size?: 200)
                optional(:max_value).maybe(:integer, gteq?: 0, lteq?: 100)
                optional(:reset_direction).filled(:integer, included_in?: [0, 1])
                optional(:resets).hash
              end
              optional(:features).maybe(:array).each(:hash) do
                optional(:id).filled(:string, :uuid_v4?)
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
                optional(:unlock).filled(:string)
              end
            end
          end
          # rubocop: enable Metrics/BlockLength

          private

          def validate_content(input)
            return unless input.key?(:id)

            input[:subclass] = ::Tlc::Homebrews::Subclass.find_by(user_id: input[:user].id, id: input[:id])
            return if input[:subclass]

            ['Not found']
          end

          def do_prepare(input)
            input[:title].transform_values! { |value| sanitize(value) }
            input[:description].transform_values! { |value| sanitize(value) }
            input[:info] = { class_id: sanitize(input[:class_id]), resources: input[:resources] || [] }
          end

          def do_persist(input)
            command =
              if input[:subclass]
                HomebrewsV2Context::Import::Tlc::Subclasses::ChangeCommand.new
              else
                HomebrewsV2Context::Import::Tlc::Subclasses::AddCommand.new
              end
            command.call(input)
          end
        end
      end
    end
  end
end
