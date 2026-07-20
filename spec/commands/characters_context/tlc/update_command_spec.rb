# frozen_string_literal: true

describe CharactersContext::Tlc::UpdateCommand do
  subject(:command_call) { instance.call(params) }

  let(:instance) { described_class.new }
  let!(:character) { create :character, :tlc }
  let(:tlc_character) { Tlc::Character.find(character.id) }

  context 'for a valid update' do
    let(:params) { { character: tlc_character, name: 'Renamed' } }

    it 'persists the change', :aggregate_failures do
      expect(command_call[:errors]).to be_blank
      expect(character.reload.name).to eq('Renamed')
    end
  end

  # AC 2
  context 'when a selected trait slug does not exist in the tlc union scope' do
    let(:params) { { character: tlc_character, selected_traits: ['daggerheart-slug'] } }

    it 'fails validation and changes nothing', :aggregate_failures do
      expect(command_call[:errors]).to include(:selected_traits)
      expect(command_call[:errors_list]).to include('Unknown trait slug')
      expect(character.reload.data.selected_traits).to eq([])
    end
  end

  # AC 3
  context 'with more than the trait cap' do
    let!(:slugs) { (1..11).map { |i| create(:feat, :tlc, slug: "trait-#{i}").slug } }
    let(:params) { { character: tlc_character, selected_traits: slugs } }

    it 'rejects 11 distinct slugs (cap 10)', :aggregate_failures do
      expect(command_call[:errors_list]).to include('Too many traits selected, limit is 10')
      expect(character.reload.data.selected_traits).to eq([])
    end
  end

  context 'with duplicate trait slugs under the cap' do
    before do
      create :feat, :tlc, slug: 'brave'
      create :feat, :tlc, slug: 'nimble'
    end

    let(:params) { { character: tlc_character, selected_traits: %w[brave brave nimble] } }

    it 'dedupes rather than errors', :aggregate_failures do
      expect(command_call[:errors]).to be_blank
      expect(character.reload.data.selected_traits).to eq(%w[brave nimble])
    end
  end

  # AC 4
  context 'when the payload smuggles the ruby-eval fields' do
    let(:params) do
      {
        character: tlc_character,
        eval_variables: { 'armor_class' => 'system("rm -rf /")' },
        description_eval_variables: { 'limit' => 'proficiency_bonus' }
      }
    end

    it 'strips them in the contract and never persists them', :aggregate_failures do
      validated = described_class.contract.call(params).to_h
      expect(validated).not_to have_key(:eval_variables)
      expect(validated).not_to have_key(:description_eval_variables)

      command_call
      data = character.reload.data.as_json
      expect(data).not_to have_key('eval_variables')
      expect(data).not_to have_key('description_eval_variables')
    end
  end

  # AC 5
  context 'with four real trait slugs and no Mixed Ancestry' do
    let!(:slugs) { %w[one two three four].map { |s| create(:feat, :tlc, slug: s).slug } }
    let(:params) { { character: tlc_character, selected_traits: slugs } }

    it 'succeeds (never-block)', :aggregate_failures do
      expect(command_call[:errors]).to be_blank
      expect(character.reload.data.selected_traits).to match_array(slugs)
      expect(character.reload.data.mixed_species).to be_nil
    end
  end
end
