# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Feats
        # Standalone homebrew feat entry point (players-guide-digest.md §6). Creates
        # the Tlc::Homebrews::Feat authoring container (info: repeatable /
        # prerequisite / unlock) plus the backing selectable Tlc::Feat row (origin
        # 'feat', origin_value = container.id) via Feats::AddCommand — so the eval
        # exclusion is enforced on this path too. Create-only, mirroring the
        # dnd2024 feat import (which has no update path).
        class PerformCommand < BaseCommand
          # rubocop: disable Metrics/BlockLength
          use_contract do
            Kinds = Dry::Types['strict.string'].enum('static', 'text', 'update_result', 'hidden')
            Limits = Dry::Types['strict.string'].enum('short_rest', 'long_rest', 'one_at_short_rest')

            params do
              required(:user).filled(type?: ::User)
              required(:title).hash do
                required(:en).filled(:string, max_size?: 50)
                optional(:ru).maybe(:string, max_size?: 50)
                optional(:es).maybe(:string, max_size?: 50)
              end
              required(:description).hash do
                required(:en).filled(:string, max_size?: 1_000)
                optional(:ru).maybe(:string, max_size?: 1_000)
                optional(:es).maybe(:string, max_size?: 1_000)
              end
              required(:kind).filled(Kinds)
              required(:level).filled(:integer, gteq?: 1)
              optional(:limit).filled(:integer, gteq?: 1)
              optional(:limit_refresh).filled(Limits)
              optional(:modifiers).hash
              optional(:continious).filled(:bool)
              optional(:static_spells).hash
              optional(:repeatable).filled(:bool)
              optional(:prerequisite).filled(:string)
              optional(:unlock).filled(:string)
              optional(:public).filled(:bool)
            end

            rule(:limit, :limit_refresh).validate(:check_all_or_nothing_present)
          end
          # rubocop: enable Metrics/BlockLength

          CONTAINER_INFO_KEYS = %i[repeatable prerequisite unlock].freeze
          FEAT_KEYS = %i[
            user title description kind level limit limit_refresh modifiers continious static_spells public unlock
          ].freeze

          private

          def do_prepare(input)
            input[:title].transform_values! { |value| sanitize(value) }
            input[:description].transform_values! { |value| sanitize(value) }
            input[:info] = input.slice(*CONTAINER_INFO_KEYS)
          end

          def do_persist(input)
            result = ActiveRecord::Base.transaction do
              container = ::Tlc::Homebrews::Feat.create!(input.slice(:user, :title, :description, :public, :info))
              add_feat.call(input.slice(*FEAT_KEYS).merge({ origin: 'feat', origin_value: container.id }))
              container
            end

            { result: result }
          end

          def add_feat = HomebrewsV2Context::Import::Tlc::Feats::AddCommand.new
        end
      end
    end
  end
end
