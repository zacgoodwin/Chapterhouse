class AddResetOnRestToFeats < ActiveRecord::Migration[8.1]
  def up
    add_column :feats, :reset_on_rest, :integer, limit: 2, comment: 'Reset selection on rest'

    Daggerheart::Character.find_each do |character|
      character.data.selected_features = character.data.selected_features.except('elemental_incarnation', 'elemental_dominion', 'elemental_aura')
      character.save
    end

    Daggerheart::Feat.find_by(slug: 'elemental_incarnation')&.update(reset_on_rest: 0)
    Daggerheart::Feat.find_by(slug: 'elemental_dominion')&.destroy

    Daggerheart::Feat.find_by(slug: 'elemental_aura')&.update(
      description: {
        en: 'While Channeling, you can assume an aura matching your element. The aura affects targets within Close range until your Incarnation ends.'
      },
      options: {},
      continious: true,
      kind: 'static'
    )

    Daggerheart::Feat.find_by(slug: 'elemental_aura_earth')&.update(
      conditions: { 'selected_feature' => 'elemental_incarnation_earth', 'subclass_mastery' => 2, 'active' => 'elemental_aura' }
    )
    Daggerheart::Feat.find_by(slug: 'elemental_aura_air')&.update(
      conditions: { 'selected_feature' => 'elemental_incarnation_air', 'subclass_mastery' => 2, 'active' => 'elemental_aura' }
    )
    Daggerheart::Feat.find_by(slug: 'elemental_aura_fire')&.update(
      conditions: { 'selected_feature' => 'elemental_incarnation_fire', 'subclass_mastery' => 2, 'active' => 'elemental_aura' }
    )
    Daggerheart::Feat.find_by(slug: 'elemental_aura_water')&.update(
      conditions: { 'selected_feature' => 'elemental_incarnation_water', 'subclass_mastery' => 2, 'active' => 'elemental_aura' }
    )

    Daggerheart::Feat.find_by(slug: 'elemental_dominion_earth')&.update(
      description: {
        en: 'When you would mark Hit Points, roll a d6 per Hit Point marked. For each result of 6, reduce the number of Hit Points you mark by 1.'
      },
      exclude: [],
      options: {},
      conditions: { 'selected_feature' => 'elemental_incarnation_earth', 'subclass_mastery' => 3 }
    )
    Daggerheart::Feat.find_by(slug: 'elemental_dominion_water')&.update(
      description: {
        en: 'When an attack against you succeeds, you can mark a Stress to make the attacker temporarily Vulnerable.'
      },
      exclude: [],
      options: {},
      conditions: { 'selected_feature' => 'elemental_incarnation_water', 'subclass_mastery' => 3 }
    )
    Daggerheart::Feat.find_by(slug: 'elemental_dominion_fire')&.update(
      description: {
        en: 'You gain a +1 situative bonus to your Proficiency for attacks and spells that deal damage.'
      },
      exclude: [],
      options: {},
      conditions: { 'selected_feature' => 'elemental_incarnation_fire', 'subclass_mastery' => 3 }
    )
    Daggerheart::Feat.find_by(slug: 'elemental_dominion_air')&.update(
      description: {
        en: 'You gain a +1 calculated bonus to your Evasion and can fly.'
      },
      exclude: [],
      options: {},
      conditions: { 'selected_feature' => 'elemental_incarnation_air', 'subclass_mastery' => 3 }
    )
  end

  def down
    remove_column :feats, :reset_on_rest
  end
end
