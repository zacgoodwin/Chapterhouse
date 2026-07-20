# frozen_string_literal: true

# Ticket #33 (E2): a standalone homebrew feat (players-guide-digest.md §6) imports
# into a Tlc::Homebrews::Feat authoring container plus its backing selectable
# Tlc::Feat row (origin 'feat'). The backing row goes through Feats::AddCommand,
# so the eval-exclusion guarantee holds on this path too.
describe HomebrewsV2Context::Import::Tlc::Feats::PerformCommand do
  subject(:command_call) { described_class.new.call(payload) }

  let(:user) { create :user }
  let(:payload) do
    {
      user: user,
      title: { en: 'Ancestral Exemplar' },
      description: { en: 'A homebrew general feat.' },
      kind: 'static',
      level: 4,
      repeatable: true,
      prerequisite: 'ruvinar_species',
      unlock: 'none'
    }
  end

  it 'creates the container and the backing feat row', :aggregate_failures do
    expect { command_call }.to change(Tlc::Homebrews::Feat, :count).by(1).and change(Tlc::Feat, :count).by(1)

    container = command_call[:result]
    expect(container).to be_a Tlc::Homebrews::Feat
    expect(container.info.repeatable).to be true
    expect(container.info.prerequisite).to eq 'ruvinar_species'

    feat = Tlc::Feat.where(origin: 'feat', origin_value: container.id).first
    expect(feat).to be_present
    expect(feat.user_id).to eq user.id
    expect(feat.info['unlock']).to eq 'none'
    expect(feat.eval_variables).to eq({})
  end
end
