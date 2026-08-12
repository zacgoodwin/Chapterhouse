# frozen_string_literal: true

module CharactersContext
  module Tlc
    # Cloned from CharactersContext::Dnd2024::CreateCommand (TLC is a D&D 2024
    # variant). Deltas vs dnd2024:
    #   * builds Tlc::Character via TlcCharacter builders (level-3 default);
    #   * accepts + validates selected_traits (union-scope slug check, cap 10,
    #     dedupe) and mixed_species;
    #   * accepts point-buy `abilities` and validates them against the PH p.38
    #     table + 27-point budget (Tlc::PointBuy) -- dnd2024 creation has no
    #     ability input at all and keeps its class standard array;
    #   * NEVER declares eval_variables / description_eval_variables — those are
    #     Ruby-eval'd feat columns (dnd2024_decorator.rb:389/:396) and stay
    #     seed-only (plan §Security T4 / decisions 16/37).
    # Config-derived enums (classes, alignments) still read the dnd2024 baseline
    # config — TLC has no distinct class/alignment config (plan P4).
    class CreateCommand < BaseCommand
      include Deps[
        refresh_feats: 'services.characters_context.tlc.refresh_feats',
        # Trait/feat attach semantics are replaced in C2; the origin-feat attach is
        # reused as-is here and is a no-op when selected_feats is empty (fresh build).
        add_talent: 'commands.characters_context.dnd2024.talents.add'
      ]

      # plan §Security threats 2/3: bound + dedupe the JSONB trait array.
      SELECTED_TRAITS_CAP = 10

      # rubocop: disable Metrics/BlockLength
      use_contract do
        config.messages.namespace = :dnd5_character

        Classes = Dry::Types['strict.string'].enum(*::Dnd2024::Character.classes_info.keys)
        Alignments = Dry::Types['strict.string'].enum(*::Dnd2024::Character::ALIGNMENTS)

        params do
          required(:user).filled(type?: User)
          required(:name).filled(:string, max_size?: 50)
          required(:species).filled(:string)
          optional(:legacy).filled(:string)
          required(:size).filled(:string)
          required(:main_class).filled(Classes)
          required(:alignment).filled(Alignments)
          optional(:background).filled(:string)
          optional(:skip_guide).filled(:bool)
          optional(:selected_traits).value(:array).each(:string)
          optional(:mixed_species).maybe(:string)
          # Point-buy range (PH 2024 p.38), NOT the 1..30 the update contract
          # allows: these are the pre-boost scores the player bought.
          optional(:abilities).hash do
            required(:str).filled(:integer, gteq?: ::Tlc::PointBuy::MIN, lteq?: ::Tlc::PointBuy::MAX)
            required(:dex).filled(:integer, gteq?: ::Tlc::PointBuy::MIN, lteq?: ::Tlc::PointBuy::MAX)
            required(:con).filled(:integer, gteq?: ::Tlc::PointBuy::MIN, lteq?: ::Tlc::PointBuy::MAX)
            required(:int).filled(:integer, gteq?: ::Tlc::PointBuy::MIN, lteq?: ::Tlc::PointBuy::MAX)
            required(:wis).filled(:integer, gteq?: ::Tlc::PointBuy::MIN, lteq?: ::Tlc::PointBuy::MAX)
            required(:cha).filled(:integer, gteq?: ::Tlc::PointBuy::MIN, lteq?: ::Tlc::PointBuy::MAX)
          end
        end

        # Defense in depth: the creation form constrains the client, so a spread
        # that costs more than 27 only arrives from a bypassed client.
        rule(:abilities) do
          next if value.blank?

          key.failure(:point_buy_budget_exceeded) unless ::Tlc::PointBuy.affordable?(value)
        end

        # Nonexistent slug = validation error (reject); a rule-breaking-but-real
        # selection (e.g. a 4th trait without Mixed Ancestry) is a soft warning
        # emitted later in C7, never a contract error (plan L539-540).
        rule(:selected_traits) do
          next if value.blank?

          uniq_slugs = value.uniq
          if uniq_slugs.size > SELECTED_TRAITS_CAP
            key.failure(:too_many_traits)
            next
          end
          unknown = uniq_slugs - ::Feat.tlc_content.where(slug: uniq_slugs).pluck(:slug)
          key.failure(:unknown_trait_slug) if unknown.any?
        end

        # Existence-only, and only "when present" (nil/blank stays allowed). Reads the
        # dnd2024 baseline species config — TLC has no distinct species config (plan P4),
        # same baseline-read as the Classes/Alignments enums above. A real-but-rule-breaking
        # Mixed Ancestry pick is a C7 soft warning, never a contract error here (plan L539-540).
        rule(:mixed_species) do
          next if value.blank?

          key.failure(:unknown_mixed_species) unless ::Dnd2024::Character.species.key?(value)
        end
      end
      # rubocop: enable Metrics/BlockLength

      private

      def do_prepare(input)
        input[:data] =
          build_fresh_character(
            input.slice(:species, :legacy, :size, :main_class, :alignment, :background, :skip_guide).symbolize_keys
          )
        input[:data][:selected_traits] = input[:selected_traits].uniq if input.key?(:selected_traits)
        input[:data][:mixed_species] = input[:mixed_species] if input.key?(:mixed_species)
        apply_point_buy_abilities(input) if input.key?(:abilities)
      end

      # Last word over TlcCharacter::Classes::*Builder, which seeds the class's
      # recommended array (itself a legal 27-point spread) for clients that send
      # no abilities at all -- e.g. the Discord bot or a skip_guide create. The
      # builder also baked its default Constitution into result[:health] (each
      # *Builder sets health to hit_die_max + con_modifier, a level-1-style
      # baseline every TLC class shares regardless of the level-3 default) --
      # swap the abilities without correcting health and a CON 15 bard keeps
      # the CON 12 default's hit points.
      def apply_point_buy_abilities(input)
        default_abilities = input[:data][:abilities]
        default_health = input[:data][:health]
        input[:data][:abilities] = input[:abilities]
        return unless default_abilities && default_health

        con_delta = ability_modifier(input[:abilities][:con]) - ability_modifier(default_abilities[:con])
        return if con_delta.zero?

        default_health[:current] += con_delta
        default_health[:max] += con_delta
      end

      def ability_modifier(score) = (score / 2) - 5

      def do_persist(input)
        character = ::Tlc::Character.create!(input.slice(:user, :name, :data))
        refresh_feats.call(character: character)

        talent = input.dig(:data, :selected_feats)
        add_talent.call(
          character: character,
          talent: ::Tlc::Feat.find_by(slug: talent) || ::Tlc::Feat.find_by(id: talent)
        )
        learn_spells_list(character, input)

        { result: character }
      end

      def build_fresh_character(data)
        TlcCharacter::BaseBuilder.new.call(result: data)
          .then { |result| TlcCharacter::SpeciesBuilder.new.call(result: result) }
          .then { |result| TlcCharacter::LegaciesBuilder.new.call(result: result) }
          .then { |result| TlcCharacter::ClassBuilder.new.call(result: result) }
          .then { |result| TlcCharacter::BackgroundBuilder.new.call(result: result) }
      end

      def learn_spells_list(character, input)
        return if ::Dnd2024::Character::CLASSES_KNOW_SPELLS_LIST.exclude?(input[:main_class])

        relation = ::Feat.tlc_content.where(origin: 6).where('origin_values && ?', "{#{input[:main_class]}}")
        spells =
          relation.where(user_id: [nil, input[:user].id]).or(relation.where(id: homebrew_item_ids(input)))
          .map do |feat|
            {
              character_id: character.id,
              feat_id: feat.id,
              ready_to_use: false,
              value: { prepared_by: input[:main_class] }
            }
          end
        ::Character::Feat.upsert_all(spells) if spells.any?
      end

      def homebrew_item_ids(input)
        ::Homebrew::Book::Item
          .where(homebrew_book_id: ::User::Book.where(user_id: input[:user]).select(:homebrew_book_id))
          .where(itemable_type: %w[Dnd2024::Feat Tlc::Feat])
          .pluck(:itemable_id)
      end
    end
  end
end
