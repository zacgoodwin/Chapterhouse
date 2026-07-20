# frozen_string_literal: true

module CharactersContext
  module Tlc
    # Cloned from CharactersContext::Dnd2024::CreateCommand (TLC is a D&D 2024
    # variant). Deltas vs dnd2024:
    #   * builds Tlc::Character via TlcCharacter builders (level-3 default);
    #   * accepts + validates selected_traits (union-scope slug check, cap 10,
    #     dedupe) and mixed_species;
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
      end

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
