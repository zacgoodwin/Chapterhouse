# frozen_string_literal: true

# Pinned-seed sampler for the parity baseline (plan acceptance test 17). Kept a
# top-level module so the sample set is computed once at load and can be redrawn
# inside an example to prove the seed is actually pinned. Samples are delta-free
# (species / legacy / class / subclass) tuples drawn from the dnd2024 base that
# tlc inherits -- the same characters both decorators must agree on.
module TlcDecoratorParity
  SEED = 424_242
  COUNT = 50

  def self.draw(seed, count)
    rng = Random.new(seed)
    species = Dnd2024::Character.species.keys
    classes = Dnd2024::Character.classes_info.keys
    Array.new(count) do
      chosen_species = species.sample(random: rng)
      chosen_class = classes.sample(random: rng)
      {
        'species' => chosen_species,
        'legacy' => Dnd2024::Character.species_info(chosen_species)['legacies'].keys.sample(random: rng),
        'main_class' => chosen_class,
        'subclass' => Dnd2024::Character.class_info(chosen_class)['subclasses'].keys.sample(random: rng)
      }
    end
  end

  SAMPLES = draw(SEED, COUNT)
end

describe TlcDecorator do
  it 'is an empty subclass of Dnd2024Decorator (overrides land in C3)', :aggregate_failures do
    expect(described_class.superclass).to eq(Dnd2024Decorator)
    expect(described_class.instance_methods(false)).to be_empty
  end

  # Acceptance criterion 4: same seed reproduces the sample set; a different seed
  # does not. Without this the parity loop below would prove nothing -- an
  # unpinned draw could silently sample the same trivial character 50 times.
  it 'draws a reproducible sample set from the pinned seed', :aggregate_failures do
    expect(TlcDecoratorParity.draw(TlcDecoratorParity::SEED, TlcDecoratorParity::COUNT)).to eq(TlcDecoratorParity::SAMPLES)
    expect(TlcDecoratorParity.draw(TlcDecoratorParity::SEED + 1, TlcDecoratorParity::COUNT)).not_to eq(TlcDecoratorParity::SAMPLES)
  end

  describe 'delta-free parity with Dnd2024Decorator' do
    let!(:character) {
      create(:character,
             :tlc,
             'data' => {
               'level' => 4,
               'main_class' => 'bard',
               'species' => 'orc',
               'classes' => { 'bard' => 4 },
               'subclasses' => { 'bard' => nil },
               'abilities' => { 'str' => 8, 'dex' => 13, 'con' => 10, 'int' => 12, 'wis' => 14, 'cha' => 15 },
               'speed' => 30
             })
    }

    # Mirror of dnd2024_decorator_spec's fixture so the parity check exercises the
    # whole pipeline: set/add modifiers, weapon attacks, feature eval, AC formula.
    before do
      create :character_bonus,
             bonusable: character,
             enabled: true,
             value: {
               'str' => { 'type' => 'add', 'value' => 1 },
               'dex' => { 'type' => 'set', 'value' => 19 },
               'initiative' => { 'type' => 'add', 'value' => 2 },
               'darkvision' => { 'type' => 'add', 'value' => 30 }
             }

      torch = create :item,
                     modifiers: {
                       'speed' => { 'type' => 'set', 'value' => 40 },
                       'initiative' => { 'type' => 'set', 'value' => 'dex + proficiency_bonus' },
                       'attack' => { 'type' => 'add', 'value' => 2 }
                     }
      melee_weapon = create :item,
                            name: { en: 'Melee' },
                            kind: 'weapon',
                            info: { type: 'melee', caption: [], damage: '1d6' },
                            modifiers: { 'damage' => { 'type' => 'add', 'value' => 2 } }
      range_weapon = create(:item,
                            kind: 'weapon',
                            name: { en: 'Range' },
                            info: { damage: '1d6', type: 'range', caption: [] })
      create :character_item, character: character, item: torch, states: Character::Item.default_states.merge('hands' => 1)
      create :character_item, character: character, item: melee_weapon, states: Character::Item.default_states.merge('hands' => 1)
      create :character_item, character: character, item: range_weapon, states: Character::Item.default_states.merge('hands' => 1)

      feat = create :feat,
                    :dnd2024_bardic_inspiration,
                    modifiers: {
                      'cha' => { 'type' => 'add', 'value' => 1 },
                      'armor_class' => {
                        'type' => 'set', 'value' => 'if (no_body_armor, MAX(armor_class, 10 + dex + cha), armor_class)'
                      }
                    }
      create :character_feat, feat: feat, character: character, ready_to_use: true
    end

    def decorated(klass)
      klass.new.call(character: Character.find(character.id)).instance_variable_get(:@result)
    end

    TlcDecoratorParity::SAMPLES.each_with_index do |sample, index|
      context "for sample #{index} (#{sample['species']}/#{sample['legacy']}/#{sample['main_class']}/#{sample['subclass']})" do
        before do
          record = Character.find(character.id)
          record.data.species = sample['species']
          record.data.legacy = sample['legacy'] if sample['legacy']
          record.data.main_class = sample['main_class']
          record.data.classes = { sample['main_class'] => 4 }
          record.data.subclasses = { sample['main_class'] => sample['subclass'] }
          record.save!
        end

        it 'produces output identical to Dnd2024Decorator' do
          expect(decorated(described_class)).to eq(decorated(Dnd2024Decorator))
        end
      end
    end
  end
end
