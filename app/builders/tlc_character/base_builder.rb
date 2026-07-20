# frozen_string_literal: true

module TlcCharacter
  class BaseBuilder
    # TLC PCs start at level 3 (players-guide-digest §2 / PH-based leveling).
    # `level` is read straight off `data.level` (decorator method_missing), so it
    # must be persisted explicitly; `classes` carries the same 3 for hit dice and
    # class-feature grants.
    START_LEVEL = 3

    def call(result:)
      result.merge({
        level: START_LEVEL,
        classes: { result[:main_class] => START_LEVEL },
        subclasses: { result[:main_class] => nil },
        weapon_core_skills: [],
        weapon_skills: [],
        armor_proficiency: [],
        languages: [],
        selected_skills: {},
        resistance: [],
        immunity: [],
        vulnerability: [],
        tools: [],
        hit_dice: { 6 => 0, 8 => 0, 10 => 0, 12 => 0 },
        guide_step: result[:skip_guide] ? nil : 1,
        skill_boosts: 0,
        any_skill_boosts: 0
      }).except(:skip_guide)
    end
  end
end
