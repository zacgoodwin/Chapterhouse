# frozen_string_literal: true

describe Tlc::Character do
  describe 'strict provider scope' do
    let!(:dnd2024_character) { create :character, :dnd2024 }
    let!(:tlc_character) { create :character, :tlc }

    # Guards the rest_controller authorization pattern: a union here would let
    # dnd2024 characters resolve on tlc endpoints (eng finding 2).
    it 'Character.tlc returns only Tlc::Character rows' do
      expect(Character.tlc.ids).to eq([tlc_character.id])
    end

    it 'Character.dnd2024 does not leak the Tlc::Character' do
      expect(Character.dnd2024.ids).to eq([dnd2024_character.id])
    end
  end

  describe 'content scopes' do
    describe 'Feat' do
      let!(:dnd2024_feat) { create :feat, :dnd2024 }
      let!(:tlc_feat) { create :feat, :tlc }

      it 'tlc is strict (own type only)' do
        expect(Feat.tlc.ids).to eq([tlc_feat.id])
      end

      it 'tlc_content unions dnd2024 + tlc rows' do
        expect(Feat.tlc_content.ids).to contain_exactly(dnd2024_feat.id, tlc_feat.id)
      end

      it 'both union rows instantiate as real STI classes' do
        expect(Feat.tlc_content.map(&:class)).to contain_exactly(Dnd2024::Feat, Tlc::Feat)
      end
    end

    # Dnd2024::Item is only a serializer namespace and Dnd2024::Spell is not a
    # class at all, so union rows are asserted via pluck (no STI instantiation).
    describe 'Item' do
      let!(:dnd2024_item) { create :item, type: 'Dnd2024::Item' }
      let!(:tlc_item) { create :item, type: 'Tlc::Item' }

      it 'tlc is strict (own type only)' do
        expect(Item.tlc.pluck(:id)).to eq([tlc_item.id])
      end

      it 'tlc_content unions dnd2024 + tlc rows' do
        expect(Item.tlc_content.pluck(:id)).to contain_exactly(dnd2024_item.id, tlc_item.id)
      end
    end

    describe 'Spell' do
      let!(:dnd2024_spell) { create :spell, :dnd2024 }
      let!(:tlc_spell) { create :spell, type: 'Tlc::Spell' }

      it 'tlc is strict (own type only)' do
        expect(Spell.tlc.pluck(:id)).to eq([tlc_spell.id])
      end

      it 'tlc_content unions dnd2024 + tlc rows' do
        expect(Spell.tlc_content.pluck(:id)).to contain_exactly(dnd2024_spell.id, tlc_spell.id)
      end
    end
  end

  describe 'TLC CharacterData defaults' do
    # A bare StoreModel applies attribute defaults for any absent key.
    let(:defaults) { Tlc::CharacterData.new }
    # Reload through STI (the factory builds the base Character class, which does
    # not cast #data). The :tlc factory data omits the five TLC fields, so a real
    # Tlc::Character surfaces those same defaults through #data.
    let(:character_data) { described_class.find(create(:character, :tlc).id).data }

    it 'defaults leyfarer_rank to 0', :aggregate_failures do
      expect(defaults.leyfarer_rank).to eq 0
      expect(character_data.leyfarer_rank).to eq 0
    end

    it 'defaults selected_traits and dismissed_warnings to []', :aggregate_failures do
      expect(defaults.selected_traits).to eq []
      expect(defaults.dismissed_warnings).to eq []
      expect(character_data.selected_traits).to eq []
      expect(character_data.dismissed_warnings).to eq []
    end

    it 'leaves leyfarer_focus and mixed_species nil', :aggregate_failures do
      expect(defaults.leyfarer_focus).to be_nil
      expect(defaults.mixed_species).to be_nil
      expect(character_data.leyfarer_focus).to be_nil
      expect(character_data.mixed_species).to be_nil
    end
  end

  describe 'StoreModel parity with Dnd2024::CharacterData' do
    # Dnd2024::CharacterData is a secondary constant in dnd2024/character.rb;
    # touch Dnd2024::Character so Zeitwerk loads the file that defines it.
    before { Dnd2024::Character }

    it 'stays a superset of Dnd2024::CharacterData (drift alarm)' do
      missing = Dnd2024::CharacterData.attribute_names - Tlc::CharacterData.attribute_names
      expect(missing).to be_empty,
                         "Tlc::CharacterData drifted from Dnd2024::CharacterData; add: #{missing.join(', ')}"
    end

    it 'adds exactly the five TLC-specific fields' do
      extra = Tlc::CharacterData.attribute_names - Dnd2024::CharacterData.attribute_names
      expect(extra).to contain_exactly(
        'leyfarer_rank', 'leyfarer_focus', 'selected_traits', 'mixed_species', 'dismissed_warnings'
      )
    end

    it 'the drift alarm fires when an upstream attribute is absent' do
      simulated_upstream = Dnd2024::CharacterData.attribute_names + ['new_upstream_field']
      expect(simulated_upstream - Tlc::CharacterData.attribute_names).to include('new_upstream_field')
    end
  end
end
