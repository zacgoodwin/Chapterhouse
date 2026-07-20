# frozen_string_literal: true

module CharactersContext
  module Tlc
    # Instantiates, recomputes and detaches a TLC character's subclass resource
    # pools (plan Phase C8) through the EXISTING character_resources/custom_resources
    # machinery (app/models/custom_resource.rb, app/models/character/resource.rb) --
    # no new resource table. Definitions live in db/data/tlc/resources.json, keyed
    # by subclass slug; call it whenever a character's classes/subclasses/level
    # change (the same trigger points CharactersContext::Dnd2024::RefreshFeats is
    # called from in create/update commands).
    #
    # Sibling to RefreshFeats rather than an extension of it: A2's
    # CharactersContext::Tlc::RefreshFeats (ticket #6) is not on master (parked),
    # so this service is self-contained and only touches resources -- it does not
    # depend on #6's branch.
    #
    # A definition's max is either:
    #   - a static integer ("max_value") for a *stored* pool the player sets by
    #     hand (Lucky Number: rolled physically, entered 1-20), or
    #   - a Dentaku formula ("max_formula") evaluated against proficiency_bonus,
    #     raw ability modifiers, and "#{class}_level" -- the same variable
    #     names Dnd2024Decorator#formula_variables uses, so a future switch to
    #     sourcing them from the decorator is a drop-in rename, not a rewrite.
    #
    # ponytail: ability modifiers here come from raw character.data.abilities,
    # not Dnd2024Decorator#modified_abilities (which folds in add/set bonuses
    # from feats/items/character_bonus). Calling character.decorator from a
    # write path would pull the full decorator pipeline (modifiers, feats,
    # items, spells) just for two numbers, and no seeded formula's acceptance
    # test needs bonus-aware ability mods. Upgrade path: swap
    # ability_modifiers's source for character.decorator.modifiers if a future
    # pool needs it.
    class RefreshResources
      include Deps[formula: 'formula', monitoring: 'monitoring.client']

      DEFINITIONS_PATH = Rails.root.join('db/data/tlc/resources.json')

      class << self
        def definitions
          @definitions ||= JSON.parse(File.read(DEFINITIONS_PATH))
        end
      end

      def call(character:)
        defs = available_defs(character)

        remove_stale(character, defs)
        defs.each { |definition| upsert_resource(character, definition) }
      end

      private

      def available_defs(character)
        data = character.data
        attached_slugs = data.subclasses.values.compact.uniq

        self.class.definitions
          .select { |entry| attached_slugs.include?(entry['subclass']) }
          .flat_map { |entry| available_resources(data, entry) }
      end

      def available_resources(data, entry)
        class_level = data.classes[entry['class']].to_i
        entry['resources'].select { |definition| class_level >= definition.fetch('min_class_level', 1) }
      end

      def remove_stale(character, defs)
        keep_slugs = defs.pluck('slug')
        stale = character.custom_resources.where.not(origin_slug: nil).where.not(origin_slug: keep_slugs)

        ::Character::Resource.where(custom_resource_id: stale.select(:id)).destroy_all
        stale.destroy_all
      end

      def upsert_resource(character, definition)
        custom_resource = ::CustomResource.find_or_initialize_by(resourceable: character, origin_slug: definition['slug'])
        max_value = resolve_max_value(character, definition)

        custom_resource.assign_attributes(
          name: definition['name'],
          description: definition['description'],
          max_value: max_value,
          reset_direction: definition['reset_direction'],
          resets: definition['resets']
        )
        custom_resource.save!

        attach_resource(character, custom_resource, definition, max_value)
      end

      def attach_resource(character, custom_resource, definition, max_value)
        resource = ::Character::Resource.find_or_initialize_by(character: character, custom_resource: custom_resource)
        resource.value = definition['reset_direction'].to_i == 1 ? max_value : 0 if resource.new_record?
        resource.value = [resource.value, max_value].min
        resource.save!
      end

      def resolve_max_value(character, definition)
        return definition['max_value'] if definition['max_formula'].blank?

        result = formula.call(formula: definition['max_formula'], variables: formula_variables(character))
        return [result.to_i, 1].max if result

        monitoring_formula_error(definition)
        [definition['max_value'].to_i, 1].max
      end

      def formula_variables(character)
        data = character.data

        { proficiency_bonus: proficiency_bonus(data.level) }
          .merge(ability_modifiers(data.abilities))
          .merge(class_level_variables(data.classes))
      end

      def proficiency_bonus(level) = 2 + ((level - 1) / 4)

      def ability_modifiers(abilities)
        abilities.to_h { |key, value| [key.to_sym, (value / 2) - 5] }
      end

      def class_level_variables(classes)
        ::Dnd2024Decorator::DEFAULT_CLASSES.index_with(0).transform_keys { |key| :"#{key}_level" }
          .merge(classes.transform_keys { |key| :"#{key}_level" }.symbolize_keys)
      end

      def monitoring_formula_error(definition)
        monitoring.notify(
          exception: Monitoring::FormulaError.new('Formula error'),
          metadata: { slug: definition['slug'], formula: definition['max_formula'] },
          severity: :info
        )
      end
    end
  end
end
