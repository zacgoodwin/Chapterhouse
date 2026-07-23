# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Feats
        # Creates ONE Tlc::Feat content row from homebrew input. Shared feature
        # creator for the species / subclass / feat container imports and the
        # standalone-feat path — mirrors Import::Dnd2024::Feats::AddCommand.
        #
        # SECURITY (plan T4 widened by decision 37, ticket A2/E1 rule): the
        # contract NEVER declares eval_variables, description_eval_variables, or
        # bonus_eval_variables, so a smuggled value is stripped by dry-validation
        # before it can reach create!. Those three columns are raw-Ruby-`eval`'d in
        # Dnd2024Decorator#eval_variable (L448), so they must stay seed-only. Unlike
        # the dnd2024 command, a per-use `limit` is stored in `info`, not in
        # description_eval_variables, so EVERY imported TLC row leaves all eval
        # fields at their empty/nil defaults.
        class AddCommand < BaseCommand
          # rubocop: disable Metrics/BlockLength
          use_contract do
            Origins = Dry::Types['strict.string'].enum('feat', 'spell', 'species', 'subclass')
            Kinds = Dry::Types['strict.string'].enum('static', 'text', 'update_result', 'hidden')
            Limits = Dry::Types['strict.string'].enum('short_rest', 'long_rest', 'one_at_short_rest')
            TraitKinds = Dry::Types['strict.string'].enum('base', 'optional')

            params do
              required(:user).filled(type?: ::User)
              required(:title).hash do
                required(:en).filled(:string, max_size?: 50)
              end
              required(:description).hash do
                required(:en).filled(:string, max_size?: 1_000)
              end
              required(:origin).filled(Origins)
              required(:origin_value).filled(:string)
              required(:kind).filled(Kinds)
              required(:level).filled(:integer, gteq?: 1)
              optional(:limit).filled(:integer, gteq?: 1)
              optional(:limit_refresh).filled(Limits)
              optional(:modifiers).hash
              optional(:continious).filled(:bool)
              optional(:static_spells).hash
              optional(:public).filled(:bool)
              # TLC species-trait / feat authoring — folded into info, never eval:
              optional(:trait_kind).filled(TraitKinds)
              optional(:is_lineage).filled(:bool)
              optional(:lineage_options).array(:hash)
              optional(:grants_free_trait).filled(:string)
              optional(:unlock).filled(:string)
            end

            rule(:limit, :limit_refresh).validate(:check_all_or_nothing_present)
          end
          # rubocop: enable Metrics/BlockLength

          INFO_ONLY_KEYS = %i[limit trait_kind is_lineage lineage_options grants_free_trait unlock].freeze
          NON_COLUMN_KEYS = %i[level static_spells].freeze

          private

          def do_prepare(input)
            input[:slug] = SecureRandom.uuid unless input.key?(:id)
            input[:conditions] = { level: input[:level] }
            input[:origin_value] = sanitize(input[:origin_value])
            input[:info] = build_info(input)
            input[:title].transform_values! { |value| sanitize(value) }
            input[:description].transform_values! { |value| sanitize(value) }
          end

          def build_info(input)
            info = {}
            info[:static_spells] = resolve_static_spells(input[:static_spells]) if input.key?(:static_spells)
            INFO_ONLY_KEYS.each { |key| info[key] = input[key] if input.key?(key) }
            info
          end

          # Map author-facing spell names to seeded Tlc::Spell-feat slugs, exactly as
          # the dnd2024 path does. Unknown names are dropped (never persisted raw).
          def resolve_static_spells(spells)
            spells.each_with_object({}) do |(key, value), acc|
              spell = ::Tlc::Feat.where(origin: 6).find_by("title ->> 'en' = ? OR title ->> 'ru' = ?", key, key)
              next unless spell

              acc[spell.slug] = value
            end
          end

          def do_persist(input)
            result = ::Tlc::Feat.create!(input.except(*INFO_ONLY_KEYS, *NON_COLUMN_KEYS))

            { result: result }
          end
        end
      end
    end
  end
end
