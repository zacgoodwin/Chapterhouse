# frozen_string_literal: true

module CharactersContext
  module Tlc
    # Cloned from CharactersContext::Dnd2024::UpdateCommand (TLC is a D&D 2024
    # variant). Deltas vs dnd2024: operates on Tlc::Character, uses the tlc
    # refresh service, accepts + validates selected_traits (union-scope slug
    # check, cap 10, dedupe) and mixed_species, and NEVER declares
    # eval_variables / description_eval_variables (Ruby-eval'd feat columns —
    # plan §Security T4). Config-derived enums read the dnd2024 baseline (plan P4).
    class UpdateCommand < BaseCommand
      include CharactersContext::AvatarAttaching
      include CharactersContext::CharacterOptions
      include CharactersContext::ClassSpellFeats
      include CharactersContext::CoinsSyncing
      include Deps[
        attach_avatar_by_url: 'commands.image_processing.attach_avatar_by_url',
        attach_avatar_by_file: 'commands.image_processing.attach_avatar_by_file',
        refresh_feats: 'services.characters_context.tlc.refresh_feats',
        cache: 'cache.avatars'
      ]

      # plan §Security threats 2/3: bound + dedupe the JSONB trait array.
      SELECTED_TRAITS_CAP = 10

      # rubocop: disable Metrics/BlockLength
      use_contract do
        config.messages.namespace = :dnd5_character

        Beastforms = Dry::Types['strict.string'].enum(*::Dnd2024::Character.beastforms.keys)

        params do
          required(:character).filled(type?: ::Tlc::Character)
          optional(:classes).hash
          optional(:subclasses).hash
          optional(:abilities).hash do
            required(:str).filled(:integer, gteq?: 1, lteq?: 30)
            required(:dex).filled(:integer, gteq?: 1, lteq?: 30)
            required(:con).filled(:integer, gteq?: 1, lteq?: 30)
            required(:int).filled(:integer, gteq?: 1, lteq?: 30)
            required(:wis).filled(:integer, gteq?: 1, lteq?: 30)
            required(:cha).filled(:integer, gteq?: 1, lteq?: 30)
          end
          optional(:health).hash do
            required(:current).filled(:integer, gteq?: 0)
            required(:max).filled(:integer, gteq?: 0)
            required(:temp).filled(:integer, gteq?: 0)
          end
          optional(:death_saving_throws).hash do
            required(:success).filled(:integer)
            required(:failure).filled(:integer)
          end
          optional(:coins).hash do
            required(:gold).filled(:integer)
            required(:silver).filled(:integer)
            required(:copper).filled(:integer)
          end
          optional(:money).filled(:integer, gteq?: 0)
          optional(:selected_skills).hash
          optional(:selected_features).hash
          optional(:selected_feats).value(:array)
          optional(:selected_traits).value(:array).each(:string)
          optional(:mixed_species).maybe(:string)
          optional(:dismissed_warnings).value(:array).each(:string)
          optional(:weapon_core_skills).value(:array).each(included_in?: WEAPON_CORE_SKILLS)
          optional(:weapon_mastery).value(:array).each(:string)
          optional(:armor_proficiency).value(:array).each(included_in?: ARMOR_PROFICIENCY)
          optional(:languages).value(:array).each(:string)
          optional(:energy).hash
          optional(:spent_spell_slots).hash
          optional(:spent_hit_dice).hash
          optional(:tools).value(:array).each(:string)
          optional(:music).value(:array).each(:string)
          optional(:resistance).value(:array).each(included_in?: DAMAGE_TYPES)
          optional(:immunity).value(:array).each(included_in?: DAMAGE_TYPES)
          optional(:vulnerability).value(:array).each(included_in?: DAMAGE_TYPES)
          optional(:name).filled(:string, max_size?: 50)
          optional(:avatar_file).hash do
            required(:file_content).filled(:string)
            required(:file_name).filled(:string)
          end
          optional(:avatar_url).filled(:string)
          optional(:file)
          optional(:selected_beastforms).maybe(:array).each(:string)
          optional(:beastform).maybe(Beastforms)
          optional(:conditions).maybe(:array).each(:string)
          optional(:guide_step).maybe(:integer)
          optional(:heroic_inspiration).filled(:bool)
          optional(:bardic_inspiration).maybe(:integer)
          optional(:exhaustion).filled(:integer)
        end

        rule(:avatar_file, :avatar_url, :file).validate(:check_only_one_present)

        # classes and subclasses must have the same keys
        rule(:classes) do
          next if value.nil?

          # add validation that main_class is present in the classes list
          key.failure(:invalid_class_name) unless value.keys.all? { |item| item.in?(::Dnd2024::Character.classes_info.keys) }
          key.failure(:invalid_level) unless value.values.all? { |item| item.to_i.between?(1, 20) }
        end

        # Nonexistent slug = reject; rule-breaking-but-real = soft warning in C7.
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
        # dnd2024 baseline species config — TLC has no distinct species config (plan P4).
        # A real-but-rule-breaking Mixed Ancestry pick is a C7 soft warning, never a
        # contract error here (plan L539-540).
        rule(:mixed_species) do
          next if value.blank?

          key.failure(:unknown_mixed_species) unless ::Dnd2024::Character.species.key?(value)
        end

        # Dismiss and restore are both a full replace of the array (same shape as
        # selected_traits): the client sends the set it wants kept. Newly ADDED
        # slugs are registry-bound, because an off-registry slug would be dead
        # state no surface can ever restore -- unlike a rule-breaking trait pick,
        # there is nothing here to warn about softly. Only the delta, though:
        # validating the whole array would freeze every later dismiss and restore
        # behind a 422 once a slug already stored is retired from the registry,
        # which is the same dead state read from the other end.
        rule(:dismissed_warnings) do
          next if value.blank?

          added = value - values[:character].data.dismissed_warnings
          key.failure(:unknown_warning_slug) unless added.all? { |slug| ::Tlc::Warnings::SLUGS.key?(slug) }
        end
      end
      # rubocop: enable Metrics/BlockLength

      private

      def lock_key(input) = "character_update_#{input[:character].id}"
      def lock_time = 0

      def do_prepare(input) # rubocop: disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
        %i[classes abilities health coins energy spent_spell_slots spent_hit_dice].each do |key|
          input[key]&.transform_values!(&:to_i)
        end

        input[:selected_traits] = input[:selected_traits].uniq if input.key?(:selected_traits)
        input[:dismissed_warnings] = input[:dismissed_warnings].uniq if input.key?(:dismissed_warnings)

        if input[:classes]
          input[:level] = input[:classes].values.sum(&:to_i)
          input[:added_classes] = input[:classes].keys - input[:character].data.classes.keys
          input[:removed_classes] = input[:character].data.classes.keys - input[:classes].keys
          input[:hit_dice] = { 6 => 0, 8 => 0, 10 => 0, 12 => 0 }
          input[:classes].each do |key, class_level|
            input[:hit_dice][::Dnd2024::Character::HIT_DICES[key]] += class_level
          end
        end

        sync_coins_and_money(input)

        if input.key?(:abilities)
          input[:ability_boosts] = 0
          input[:leveling_ability_boosts] = 0
          input[:leveling_ability_boosts_list] = []
        end
        if input.key?(:selected_skills)
          input[:any_skill_boosts] = 0
          input[:skill_boosts] = 0
          input[:skill_boosts_list] = []
        end
      end

      def do_persist(input) # rubocop: disable Metrics/AbcSize
        input[:character].data =
          input[:character].data.attributes.merge(
            input.except(:character, :avatar_file, :avatar_url, :file, :name).stringify_keys
          )
        input[:character].assign_attributes(input.slice(:name))
        input[:character].save!

        if %i[classes subclasses selected_features selected_feats].intersect?(input.keys)
          refresh_feats.call(character: input[:character])
        end
        refresh_class_spells(input) if input[:classes]
        upload_avatar(input)

        { result: input[:character] }
      end

      # TLC reads the union content scope, and owns both dnd2024 and tlc homebrew feats.
      def spell_feats_scope = ::Feat.tlc_content
      def homebrew_feat_types = %w[Dnd2024::Feat Tlc::Feat]
    end
  end
end
