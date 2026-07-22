# frozen_string_literal: true

# Unit coverage for the soft-warning engine, one describe per warning family,
# plus the registry-drift gate that pins every slug to an i18n message and to a
# check method. The end-to-end acceptance cases (serialize, dismiss, restore)
# live in spec/requests/frontend/tlc/characters_spec.rb.
#
# `Character.find` rather than the factory's return value: spec/factories/
# characters.rb builds a base Character row with `type` set, so only a re-find
# instantiates the Tlc::Character that owns `decorator` and the StoreModel data.
describe Tlc::Warnings do
  subject(:warnings) { described_class.call(decorator: Character.find(character.id).decorator) }

  let(:overrides) { {} }
  let!(:character) { create :character, :tlc, data: tlc_data(overrides) }
  let(:i18n) {
    JSON.parse(Rails.root.join('app/javascript/applications/CharKeeperApp/i18n/en.json').read)
  }

  def slugs = warnings.pluck(:slug)

  def entry(slug) = warnings.find { |item| item[:slug] == slug }

  # The tlc factory's data hash with the given keys replaced. Spelled out rather
  # than reaching into the factory so a change there cannot silently retune a
  # threshold this file asserts on.
  def tlc_data(changes)
    {
      'level' => 4, 'species' => 'human', 'main_class' => 'bard', 'classes' => { 'bard' => 4 },
      'subclasses' => { 'bard' => nil },
      'abilities' => { 'str' => 13, 'dex' => 16, 'con' => 14, 'int' => 11, 'wis' => 16, 'cha' => 10 },
      'speed' => 30
    }.merge(changes)
  end

  describe 'the registry' do
    it 'gives every slug an en.json message under the derived key' do
      missing = described_class::SLUGS.keys.reject { |slug|
        i18n.dig(*described_class.message_key(slug).split('.')).present?
      }

      expect(missing).to be_empty
    end

    it 'ships the same key set in every frontend locale' do
      others = %w[ru es].map { |locale|
        JSON.parse(Rails.root.join("app/javascript/applications/CharKeeperApp/i18n/#{locale}.json").read)
            .fetch('warnings').keys.sort
      }

      expect(others).to all(eq(i18n.fetch('warnings').keys.sort))
    end

    it 'implements a check for every slug' do
      unimplemented = described_class::SLUGS.keys.reject { |slug| described_class.private_method_defined?(slug) }

      expect(unimplemented).to be_empty
    end

    it 'sources every slug as PHB or TLC' do
      expect(described_class::SLUGS.values.uniq.sort).to eq [described_class::PHB, described_class::TLC]
    end

    # ch8 -> 12 ... ch16 -> 20 (Players Guide Table 2, §10). Pinned literally so
    # a refactor of the generator cannot silently shift the table.
    it 'matches the published level-cap table', :aggregate_failures do
      expect(described_class::LEVEL_CAP_BY_CHAPTER[8]).to eq 12
      expect(described_class::LEVEL_CAP_BY_CHAPTER[16]).to eq 20
      expect(described_class::LEVEL_CAP_BY_CHAPTER.keys).to eq (8..16).to_a
    end
  end

  describe 'a character breaking no rules' do
    it 'produces no warnings' do
      expect(warnings).to be_empty
    end
  end

  describe 'multiclass_prereq' do
    # Orc, not the factory's Human: Greenhorn would bypass the whole check.
    # Paladin needs STR 13 AND CHA 13; STR 12 fails it (acceptance test 7).
    let(:overrides) {
      {
        'species' => 'orc', 'classes' => { 'bard' => 3, 'paladin' => 1 },
        'abilities' => { 'str' => 12, 'dex' => 10, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 16 }
      }
    }

    it 'warns with a PHB source when a multiclass prerequisite is unmet', :aggregate_failures do
      expect(entry('multiclass_prereq')).to include(
        source: 'PHB', message_key: 'warnings.multiclassPrereq', dismissible: true
      )
      expect(entry('multiclass_prereq')[:context][:classes]).to eq ['paladin']
      expect(entry('multiclass_prereq')[:context][:minimum]).to eq 13
      expect(entry('multiclass_prereq')[:context][:required]).to eq({ 'paladin' => [%w[str], %w[cha]] })
    end

    context 'when every prerequisite is met' do
      let(:overrides) {
        super().merge('abilities' => { 'str' => 13, 'dex' => 10, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 16 })
      }

      it 'does not warn' do
        expect(slugs).not_to include 'multiclass_prereq'
      end
    end

    # Paladin alone, still STR 12: the prerequisite is unmet, but you only need
    # it to MULTIclass, so a single-class build is silent. Deliberately not a
    # class that meets its own prereq -- that would pass with the guard deleted.
    context 'with a single class whose own prerequisite is unmet' do
      let(:overrides) {
        super().merge('main_class' => 'paladin', 'classes' => { 'paladin' => 4 }, 'subclasses' => { 'paladin' => nil })
      }

      it 'does not warn' do
        expect(slugs).not_to include 'multiclass_prereq'
      end
    end

    context 'with an either-or prerequisite' do
      # Fighter is the table's only "Strength OR Dexterity" row; the Paladin
      # case above is the "AND" row, so both branches of the AND/OR shape run.
      let(:overrides) {
        super().merge(
          'classes' => { 'bard' => 3, 'fighter' => 1 },
          'abilities' => { 'str' => 8, 'dex' => 13, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 16 }
        )
      }

      it 'treats one satisfied ability as enough' do
        expect(slugs).not_to include 'multiclass_prereq'
      end
    end

    it 'reads decorated ability scores, not the raw ones' do
      create :character_bonus, bonusable: character, enabled: true,
                               value: { 'str' => { 'type' => 'add', 'value' => 1 } }

      expect(slugs).not_to include 'multiclass_prereq'
    end

    describe 'Human Greenhorn bypass (players-guide-digest.md:60)' do
      context 'with a Human' do
        let(:overrides) { super().merge('species' => 'human') }

        it 'stays silent' do
          expect(slugs).not_to include 'multiclass_prereq'
        end
      end

      context 'with a Mixed Ancestry Human' do
        let(:overrides) { super().merge('mixed_species' => 'human') }

        it 'stays silent' do
          expect(slugs).not_to include 'multiclass_prereq'
        end
      end
    end
  end

  describe 'trait_count' do
    let(:overrides) { { 'selected_traits' => %w[a b c d] } }

    it 'warns with a TLC source above the base allowance of 3', :aggregate_failures do
      expect(entry('trait_count')).to include(source: 'TLC', message_key: 'warnings.traitCount', dismissible: true)
      expect(entry('trait_count')[:context]).to eq({ selected: 4, allowed: 3 })
    end

    context 'with exactly 3 traits' do
      let(:overrides) { { 'selected_traits' => %w[a b c] } }

      it 'stays silent' do
        expect(slugs).not_to include 'trait_count'
      end
    end

    context 'with Mixed Ancestry' do
      let(:overrides) { super().merge('mixed_species' => 'elf') }

      it 'allows a fourth trait' do
        expect(slugs).not_to include 'trait_count'
      end
    end

    context 'with Mixed Ancestry and five traits' do
      let(:overrides) { { 'selected_traits' => %w[a b c d e], 'mixed_species' => 'elf' } }

      it 'warns against the raised allowance' do
        expect(entry('trait_count')[:context]).to eq({ selected: 5, allowed: 4 })
      end
    end
  end

  describe 'prepared_overrun' do
    # A level-4 bard prepares class_level + 3 = 7 (bard_decorator.rb:52).
    def prepare(count, level: 1, ready: true)
      Array.new(count) do
        spell = create :feat, :tlc, origin: 6, info: { 'level' => level }
        create :character_feat, character: character, feat: spell,
                                ready_to_use: ready, value: { 'prepared_by' => 'bard' }
      end
    end

    it 'warns with a PHB source when a class is over its prepared allowance', :aggregate_failures do
      prepare(8)

      expect(entry('prepared_overrun')).to include(
        source: 'PHB', message_key: 'warnings.preparedOverrun', dismissible: true
      )
      expect(entry('prepared_overrun')[:context]).to eq({ 'bard' => { prepared: 8, allowed: 7 } })
    end

    it 'stays silent at exactly the allowance' do
      prepare(7)

      expect(slugs).not_to include 'prepared_overrun'
    end

    it 'ignores cantrips' do
      prepare(7)
      prepare(4, level: 0)

      expect(slugs).not_to include 'prepared_overrun'
    end

    it 'ignores spells that are known but not prepared' do
      prepare(7)
      prepare(4, ready: false)

      expect(slugs).not_to include 'prepared_overrun'
    end
  end

  describe 'level_vs_chapter_cap' do
    let(:overrides) { { 'level' => 13, 'classes' => { 'bard' => 13 } } }
    let(:chapter) { 8 }
    let!(:campaign) { create :campaign, :tlc, chapter: chapter }

    before { create :campaign_character, campaign: campaign, character: character }

    it 'warns with a TLC source above the chapter cap', :aggregate_failures do
      expect(entry('level_vs_chapter_cap')).to include(
        source: 'TLC', message_key: 'warnings.levelVsChapterCap', dismissible: true
      )
      expect(entry('level_vs_chapter_cap')[:context]).to eq({ level: 13, cap: 12, chapter: 8 })
    end

    context 'with the level exactly at the cap' do
      let(:chapter) { 9 }

      it 'stays silent' do
        expect(slugs).not_to include 'level_vs_chapter_cap'
      end
    end

    context 'with no chapter set' do
      let(:chapter) { nil }

      it 'stays silent' do
        expect(slugs).not_to include 'level_vs_chapter_cap'
      end
    end

    context 'with a chapter below the published table' do
      let(:chapter) { 3 }

      it 'stays silent' do
        expect(slugs).not_to include 'level_vs_chapter_cap'
      end
    end

    it 'uses the earliest chapter when the PC plays in two campaigns' do
      create :campaign_character, campaign: create(:campaign, :tlc, chapter: 16), character: character

      expect(entry('level_vs_chapter_cap')[:context]).to eq({ level: 13, cap: 12, chapter: 8 })
    end
  end

  describe 'banned_spell_exempted' do
    it 'warns with a TLC source for an attached exempted grant', :aggregate_failures do
      granting = create :feat, :tlc, slug: 'lady_of_ivory', info: { 'banned_exemption' => true }
      create :character_feat, character: character, feat: granting

      expect(entry('banned_spell_exempted')).to include(
        source: 'TLC', message_key: 'warnings.bannedSpellExempted', dismissible: true
      )
      expect(entry('banned_spell_exempted')[:context]).to eq({ feats: ['lady_of_ivory'] })
    end

    it 'stays silent for an ordinary attached feat' do
      create :character_feat, character: character, feat: create(:feat, :tlc)

      expect(slugs).not_to include 'banned_spell_exempted'
    end

    it 'stays silent for an exempted row the character does not hold' do
      create :feat, :tlc, slug: 'unheld', info: { 'banned_exemption' => true }

      expect(slugs).not_to include 'banned_spell_exempted'
    end

    # Tlc::Seeder lints spells.json and items.json too, so the flag reaches all
    # three content tables; an exempted item that never warned would be a seed
    # gate with no runtime half.
    it 'warns for an exempted item the character carries' do
      granting = create :item, :tlc, slug: 'ivory_key', info: { 'banned_exemption' => true }
      create :character_item, character: character, item: granting

      expect(entry('banned_spell_exempted')[:context]).to eq({ items: ['ivory_key'] })
    end

    # Spells fold the flag into `data`, not `info` (seeder.rb META_COLUMN).
    it 'warns for an exempted spell the character knows' do
      granting = create :spell, :tlc, slug: 'ivory_word', data: { 'banned_exemption' => true }
      create :character_spell, character: character, spell: granting

      expect(entry('banned_spell_exempted')[:context]).to eq({ spells: ['ivory_word'] })
    end

    it 'names every carrying surface in one entry' do
      create :character_feat, character: character,
                              feat: create(:feat, :tlc, slug: 'lady_of_ivory', info: { 'banned_exemption' => true })
      create :character_item, character: character,
                              item: create(:item, :tlc, slug: 'ivory_key', info: { 'banned_exemption' => true })
      create :character_spell, character: character,
                               spell: create(:spell, :tlc, slug: 'ivory_word', data: { 'banned_exemption' => true })

      expect(entry('banned_spell_exempted')[:context]).to eq(
        { feats: ['lady_of_ivory'], items: ['ivory_key'], spells: ['ivory_word'] }
      )
    end

    it 'stays silent for ordinary attached items and spells' do
      create :character_item, character: character, item: create(:item, :tlc)
      create :character_spell, character: character, spell: create(:spell, :tlc)

      expect(slugs).not_to include 'banned_spell_exempted'
    end
  end

  describe 'trait_unavailable' do
    let(:overrides) { { 'selected_traits' => %w[kept deleted] } }

    before { create :feat, :tlc, slug: 'kept' }

    it 'warns with a TLC source for a selected trait with no content row', :aggregate_failures do
      expect(entry('trait_unavailable')).to include(
        source: 'TLC', message_key: 'warnings.traitUnavailable', dismissible: true
      )
      expect(entry('trait_unavailable')[:context]).to eq({ traits: ['deleted'] })
    end

    it 'stays silent when every selected trait resolves' do
      create :feat, :tlc, slug: 'deleted'

      expect(slugs).not_to include 'trait_unavailable'
    end

    # The lookup is Feat.tlc_content (Dnd2024 + Tlc), the same union the update
    # contract validates against. A Dnd5 row wearing the slug is not TLC content
    # and must not silence the warning.
    it 'ignores a same-slug row outside the TLC content union' do
      create :feat, :dnd5, slug: 'deleted', origin: 2, kind: 0

      expect(entry('trait_unavailable')[:context]).to eq({ traits: ['deleted'] })
    end
  end
end
