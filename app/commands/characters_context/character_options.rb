# frozen_string_literal: true

module CharactersContext
  # Enumerations the provider update contracts validate arrays against. The
  # dnd5, dnd2024 and TLC rule sets share every list here.
  module CharacterOptions
    SKILLS = %w[
      acrobatics animal arcana athletics deception history insight intimidation investigation
      medicine nature perception performance persuasion religion sleight stealth survival
    ].freeze
    WEAPON_CORE_SKILLS = %w[light martial].freeze
    ARMOR_PROFICIENCY = %w[light medium heavy shield].freeze
    DAMAGE_TYPES = %w[
      bludge pierce slash acid cold fire force lighting necrotic
      poison psychic radiant thunder
    ].freeze
  end
end
