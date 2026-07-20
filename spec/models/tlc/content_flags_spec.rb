# frozen_string_literal: true

# Gate tests for the TLC visibility + verified meta layer (ticket #32, step 4).
# These are the semantics the parked C5 options + D2 list tickets consume, so
# they are asserted here at the query layer per each plan acceptance criterion.
describe Tlc::ContentFlags do
  def tlc_feat(visibility: 'public', **attrs)
    create(:feat, :tlc, **attrs).tap { |feat| feat.update!(visibility: visibility) }
  end

  describe 'visibility default + validation' do
    it 'defaults to public and rejects an unknown value', :aggregate_failures do
      feat = create(:feat, :tlc)

      expect(feat.visibility).to eq('public')
      feat.visibility = 'bogus'
      expect(feat).not_to be_valid
      expect(feat.errors[:visibility]).to be_present
    end
  end

  describe '.addable (options browse list)' do
    it 'offers only public rows', :aggregate_failures do
      public_feat = tlc_feat(visibility: 'public')
      locked_feat = tlc_feat(visibility: 'locked')
      deprecated_feat = tlc_feat(visibility: 'deprecated')
      hidden_feat = tlc_feat(visibility: 'hidden')

      addable = Tlc::Feat.addable

      expect(addable).to include(public_feat)
      expect(addable).not_to include(locked_feat, deprecated_feat, hidden_feat)
    end
  end

  describe 'locked (acceptance: not addable/searchable; existing holder keeps it)' do
    let!(:locked_feat) { tlc_feat(visibility: 'locked', slug: 'ward', title: { 'en' => 'Ward' }) }
    let!(:holding) { create(:character_feat, feat: locked_feat) }

    it 'is absent from addable and from an exact search, yet the holding survives', :aggregate_failures do
      expect(Tlc::Feat.addable).not_to include(locked_feat)
      expect(Tlc::Feat.searchable('Ward')).not_to include(locked_feat)
      # The scope governs what the options path OFFERS, never existing holdings.
      expect(Character::Feat.where(feat: locked_feat)).to include(holding)
    end
  end

  describe 'hidden (acceptance: only an exact-name match surfaces it)' do
    let!(:hidden_feat) { tlc_feat(visibility: 'hidden', slug: 'shadow_ward', title: { 'en' => 'Shadow Ward' }) }

    it 'surfaces on an exact name or slug match but never on a partial or the browse list', :aggregate_failures do
      expect(Tlc::Feat.searchable('Shadow Ward')).to include(hidden_feat)
      expect(Tlc::Feat.searchable('shadow_ward')).to include(hidden_feat)
      expect(Tlc::Feat.searchable('Shadow')).not_to include(hidden_feat)
      expect(Tlc::Feat.addable).not_to include(hidden_feat)
    end
  end

  describe '.searchable public rows' do
    it 'matches public rows on a partial, case-insensitive name', :aggregate_failures do
      public_feat = tlc_feat(visibility: 'public', slug: 'lantern', title: { 'en' => 'Ley Lantern' })

      expect(Tlc::Feat.searchable('lantern')).to include(public_feat)
      expect(Tlc::Feat.searchable('nomatch')).not_to include(public_feat)
    end
  end

  describe '.where_verified (verification queue filter)' do
    it 'returns only rows explicitly gated verified:false (default is true)', :aggregate_failures do
      verified_feat = create(:feat, :tlc)
      unverified_feat = create(:feat, :tlc).tap { |feat| feat.update!(verified: false) }

      queue = Tlc::Feat.where_verified(false)

      expect(queue).to include(unverified_feat)
      expect(queue).not_to include(verified_feat)
      expect(verified_feat.verified?).to be(true)
      expect(unverified_feat.verified?).to be(false)
    end
  end

  describe 'meta column placement per STI class' do
    it 'stores visibility in info for feats/items and data for spells', :aggregate_failures do
      feat = create(:feat, :tlc).tap { |row| row.update!(visibility: 'locked') }
      item = create(:item, :tlc).tap { |row| row.update!(visibility: 'hidden') }
      spell = create(:spell, :tlc).tap { |row| row.update!(visibility: 'deprecated') }

      expect(feat.info['visibility']).to eq('locked')
      expect(item.info['visibility']).to eq('hidden')
      expect(spell.data['visibility']).to eq('deprecated')
    end
  end
end
