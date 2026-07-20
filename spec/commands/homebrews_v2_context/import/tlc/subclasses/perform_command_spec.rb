# frozen_string_literal: true

# Ticket #33 (E2) acceptance test 3 — import half. A homebrew subclass with a
# resource definition and a level-gated feature imports into a
# Tlc::Homebrews::Subclass container (info carries class_id + the C8-shaped
# resource) plus Tlc::Feat feature rows (origin 'subclass', conditions.level set
# so RefreshFeats attaches each at the right subclass level). The instantiate-via-C8
# half is proven in spec/services/characters_context/tlc/refresh_resources_homebrew_spec.rb.
describe HomebrewsV2Context::Import::Tlc::Subclasses::PerformCommand do
  subject(:command_call) { described_class.new.call(payload) }

  let(:user) { create :user }
  let(:payload) do
    {
      user: user,
      title: { en: 'Gambler' },
      description: { en: 'A homebrew subclass.' },
      class_id: 'rogue',
      resources: [
        {
          slug: 'gambler_lucky_number',
          name: 'Lucky Number',
          description: 'A d20 stored each long rest.',
          min_class_level: 3,
          max_value: 20,
          reset_direction: 0,
          resets: { long: -1 }
        }
      ],
      features: [
        { title: { en: 'High Roller' }, description: { en: 'Level 3 feature.' }, kind: 'static', level: 3 },
        { title: { en: 'Hedge Your Bets' }, description: { en: 'Level 9 feature.' }, kind: 'static', level: 9 }
      ]
    }
  end

  it 'creates the subclass with its resource definition and level-gated features', :aggregate_failures do
    expect { command_call }.to change(Tlc::Homebrews::Subclass, :count).by(1).and change(Tlc::Feat, :count).by(2)

    subclass = command_call[:result]
    expect(subclass.info.class_id).to eq 'rogue'
    expect(subclass.info.resources.size).to eq 1
    expect(subclass.info.resources.first['slug']).to eq 'gambler_lucky_number'

    features = Tlc::Feat.where(origin: 'subclass', origin_value: subclass.id).order(:created_at)
    expect(features.map { |feature| feature.conditions['level'] }).to contain_exactly(3, 9)
  end

  it 'excludes eval fields from the imported subclass features', :aggregate_failures do
    command_call
    subclass = Tlc::Homebrews::Subclass.last

    Tlc::Feat.where(origin: 'subclass', origin_value: subclass.id).find_each do |feature|
      expect(feature.eval_variables).to eq({})
      expect(feature.description_eval_variables).to eq({})
      expect(feature.bonus_eval_variables).to be_nil
    end
  end
end
