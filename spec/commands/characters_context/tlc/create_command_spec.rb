# frozen_string_literal: true

describe CharactersContext::Tlc::CreateCommand do
  subject(:command_call) { instance.call(params) }

  let(:instance) { described_class.new }
  let(:user) { create :user }
  let(:valid_params) do
    {
      user: user, name: 'Leyfarer', alignment: 'neutral', main_class: 'bard', species: 'human', size: 'medium'
    }
  end

  # PH p.38 27-point-buy cost table. A persisted create must spend exactly 27.
  let(:point_buy_cost) { { 8 => 0, 9 => 1, 10 => 2, 11 => 3, 12 => 4, 13 => 5, 14 => 7, 15 => 9 } }
  # 9 + 7 + 5 + 4 + 2 + 0 = 27, the standard array spread the form can also buy.
  let(:point_buy_abilities) { { str: 15, dex: 14, con: 13, int: 12, wis: 10, cha: 8 } }

  # AC 1
  context 'for a valid tlc create payload' do
    let(:params) { valid_params }

    it 'persists a level-3 Tlc::Character with point-buy scores', :aggregate_failures do
      expect { command_call }.to change(user.characters, :count).by(1)

      character = command_call[:result]
      expect(character).to be_a(Tlc::Character)
      expect(character.data.level).to eq(3)
      expect(character.data.classes).to eq('bard' => 3)

      spent = character.data.abilities.values.sum { |score| point_buy_cost.fetch(score.to_i) }
      expect(spent).to eq(27)
    end
  end

  # Point buy (issue #80). The form constrains the client; these gate the server,
  # which has to hold on its own when the client is bypassed.
  context 'with an affordable point-buy spread' do
    let(:params) { valid_params.merge(abilities: point_buy_abilities) }

    it 'persists the bought scores over the class recommendation', :aggregate_failures do
      expect { command_call }.to change(Tlc::Character, :count).by(1)
      expect(command_call[:errors]).to be_blank
      # Reload: what matters is the spread that survived the JSONB round trip,
      # not the symbol-keyed hash still sitting in memory.
      expect(command_call[:result].reload.data.abilities.symbolize_keys).to eq(point_buy_abilities)
    end
  end

  context 'with a spread that costs more than the 27-point budget' do
    # 36 points. Every score is inside 8..15 -- only the total is out of bounds,
    # so the range check alone would let this through.
    let(:params) { valid_params.merge(abilities: { str: 15, dex: 15, con: 15, int: 15, wis: 8, cha: 8 }) }

    it 'fails validation and persists nothing', :aggregate_failures do
      expect(point_buy_abilities.values.sum { |score| point_buy_cost.fetch(score) }).to eq(27)
      expect { command_call }.not_to change(Character, :count)
      expect(command_call[:errors]).to include(:abilities)
      expect(command_call[:errors_list]).to include('Ability scores must cost 27 points or fewer in point buy')
    end
  end

  # Per-score schema errors come back flattened (BaseCommand#flatten_hash_from),
  # so the key is `abilities.<score>` rather than `abilities`.
  context 'with a score above the 15 ceiling' do
    let(:params) { valid_params.merge(abilities: point_buy_abilities.merge(cha: 16)) }

    it 'fails validation and persists nothing', :aggregate_failures do
      expect { command_call }.not_to change(Character, :count)
      expect(command_call[:errors]).to include(:'abilities.cha')
    end
  end

  context 'with a score below the 8 floor' do
    let(:params) { valid_params.merge(abilities: point_buy_abilities.merge(str: 7)) }

    it 'fails validation and persists nothing', :aggregate_failures do
      expect { command_call }.not_to change(Character, :count)
      expect(command_call[:errors]).to include(:'abilities.str')
    end
  end

  context 'with an incomplete abilities hash' do
    let(:params) { valid_params.merge(abilities: { str: 15, dex: 14 }) }

    it 'fails validation on every missing score, not just some', :aggregate_failures do
      expect { command_call }.not_to change(Character, :count)
      expect(command_call[:errors].keys).to include(
        :'abilities.con', :'abilities.int', :'abilities.wis', :'abilities.cha'
      )
    end
  end

  context 'with a Constitution score above the bard class-builder default' do
    # Bard's class-builder default is con: 12 (modifier +1); con: 15 here is
    # modifier +2, one point higher -- health must track the bought score,
    # not the recommended array the builder computed it against.
    let(:params) { valid_params.merge(abilities: point_buy_abilities.merge(con: 15, str: 13)) }

    it 'raises max and current health by the constitution modifier delta', :aggregate_failures do
      expect(point_buy_abilities.merge(con: 15, str: 13).values.sum { |score| point_buy_cost.fetch(score) })
        .to eq(27)

      data = command_call[:result].reload.data
      expect(data.health['max']).to eq(10)
      expect(data.health['current']).to eq(10)
    end
  end

  # AC 2
  context 'when a selected trait slug does not exist in the tlc union scope' do
    let(:params) { valid_params.merge(selected_traits: ['daggerheart-slug']) }

    it 'fails validation and persists nothing', :aggregate_failures do
      expect { command_call }.not_to change(Character, :count)
      expect(command_call[:errors]).to include(:selected_traits)
      expect(command_call[:errors_list]).to include('Unknown trait slug')
    end
  end

  # AC 3
  context 'with more than the trait cap' do
    let!(:slugs) { (1..11).map { |i| create(:feat, :tlc, slug: "trait-#{i}").slug } }
    let(:params) { valid_params.merge(selected_traits: slugs) }

    it 'rejects 11 distinct slugs (cap 10) and persists nothing', :aggregate_failures do
      expect { command_call }.not_to change(Character, :count)
      expect(command_call[:errors_list]).to include('Too many traits selected, limit is 10')
    end
  end

  context 'with duplicate trait slugs under the cap' do
    before do
      create :feat, :tlc, slug: 'brave'
      create :feat, :tlc, slug: 'nimble'
    end

    let(:params) { valid_params.merge(selected_traits: %w[brave brave nimble]) }

    it 'dedupes rather than errors', :aggregate_failures do
      expect { command_call }.to change(Tlc::Character, :count).by(1)
      expect(command_call[:errors]).to be_blank
      expect(command_call[:result].data.selected_traits).to eq(%w[brave nimble])
    end
  end

  # AC 4 — the Ruby-eval surface (feat eval_variables/description_eval_variables) is seed-only.
  context 'when the payload smuggles the ruby-eval fields' do
    let(:params) do
      valid_params.merge(
        eval_variables: { 'armor_class' => 'system("rm -rf /")' },
        description_eval_variables: { 'limit' => 'proficiency_bonus' }
      )
    end

    it 'strips them in the contract and never persists them', :aggregate_failures do
      validated = described_class.contract.call(params).to_h
      expect(validated).not_to have_key(:eval_variables)
      expect(validated).not_to have_key(:description_eval_variables)

      expect { command_call }.to change(Tlc::Character, :count).by(1)
      data = command_call[:result].reload.data.as_json
      expect(data).not_to have_key('eval_variables')
      expect(data).not_to have_key('description_eval_variables')
    end
  end

  # AC 5 — a 4th trait without Mixed Ancestry is rule-breaking-but-real: never a contract error
  # (the soft warning is emitted in C7).
  context 'with four real trait slugs and no Mixed Ancestry' do
    let!(:slugs) { %w[one two three four].map { |s| create(:feat, :tlc, slug: s).slug } }
    let(:params) { valid_params.merge(selected_traits: slugs) }

    it 'succeeds (never-block)', :aggregate_failures do
      expect { command_call }.to change(Tlc::Character, :count).by(1)
      expect(command_call[:errors]).to be_blank
      expect(command_call[:result].data.selected_traits).to match_array(slugs)
      expect(command_call[:result].data.mixed_species).to be_nil
    end
  end

  # mixed_species existence rule (human-decided: validate now). Existence only —
  # 'elf' is a real dnd2024 baseline species key; a rule-breaking-but-real pick is
  # still a C7 soft warning, never a contract error.
  context 'with a real mixed_species id' do
    let(:params) { valid_params.merge(mixed_species: 'elf') }

    it 'succeeds and persists it', :aggregate_failures do
      expect { command_call }.to change(Tlc::Character, :count).by(1)
      expect(command_call[:errors]).to be_blank
      expect(command_call[:result].data.mixed_species).to eq('elf')
    end
  end

  context 'with a nonexistent mixed_species id' do
    let(:params) { valid_params.merge(mixed_species: 'daggerheart-race') }

    it 'fails validation and persists nothing', :aggregate_failures do
      expect { command_call }.not_to change(Character, :count)
      expect(command_call[:errors]).to include(:mixed_species)
      expect(command_call[:errors_list]).to include('Unknown mixed species')
    end
  end

  context 'for invalid params' do
    context 'without species' do
      let(:params) { valid_params.merge(species: nil).compact }

      it 'does not create character', :aggregate_failures do
        expect { command_call }.not_to change(user.characters, :count)
        expect(command_call[:errors_list]).not_to be_nil
      end
    end
  end
end
