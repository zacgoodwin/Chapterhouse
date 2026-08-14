# frozen_string_literal: true

# TLC ships builders for most of the config classes; the rest fall back to
# DummyBuilder. The set is derived rather than hardcoded so adding a builder
# flips the expectation instead of leaving a stale skip behind.
missing_tlc_class_builders =
  Dnd2024::Character.classes_info.keys.reject do |slug|
    "TlcCharacter::Classes::#{slug.camelize}Builder".safe_constantize.present?
  end

describe TlcCharacter::ClassBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { TlcCharacter::BaseBuilder.new.call(result: { main_class: main_class, species: 'human' }) }

  context 'with a known class' do
    let(:main_class) { 'paladin' }

    it 'applies the class proficiencies and standard array', :aggregate_failures do
      expect(build[:weapon_core_skills]).to eq(%w[light martial])
      expect(build[:armor_proficiency]).to eq(%w[light medium heavy shield])
      expect(build[:abilities]).to eq(str: 15, dex: 10, con: 13, int: 8, wis: 12, cha: 14)
    end

    # Unlike dnd2024 (always 1), TLC seeds the pool with the level-3 start level.
    it 'fills the class hit dice slot with the class level' do
      expect(build[:hit_dice]).to eq(6 => 0, 8 => 0, 10 => TlcCharacter::BaseBuilder::START_LEVEL, 12 => 0)
    end
  end

  Dnd2024::Character.classes_info.each_key do |class_slug|
    context "with #{class_slug}" do
      let(:main_class) { class_slug }

      it 'fills the hit dice slot from HIT_DICES' do
        expect(build[:hit_dice][Dnd2024::Character::HIT_DICES[class_slug]])
          .to eq(TlcCharacter::BaseBuilder::START_LEVEL)
      end

      if missing_tlc_class_builders.include?(class_slug)
        it 'has no TLC class builder, so abilities and health stay unset', :aggregate_failures do
          expect(build).not_to have_key(:abilities)
          expect(build).not_to have_key(:health)
        end
      else
        it 'assigns abilities, health and class skill boosts', :aggregate_failures do
          expect(build[:abilities].keys).to contain_exactly(:str, :dex, :con, :int, :wis, :cha)
          expect(build[:health]).to include(temp: 0)
          expect(build[:health][:current]).to eq(build[:health][:max])
          expect(build[:skill_boosts] + build[:any_skill_boosts]).to be_positive
        end
      end
    end
  end

  context 'with an unknown class' do
    let(:main_class) { 'bardbarian' }

    it 'falls back to the dummy builder' do
      expect(build).not_to have_key(:abilities)
    end
  end
end
