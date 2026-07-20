# frozen_string_literal: true

describe CustomResource do
  it 'factory should be valid' do
    custom_resource = build :custom_resource

    expect(custom_resource).to be_valid
  end

  describe '#refreshed_value' do
    it 'resets to 0 on a full reset when reset_direction is 0' do
      custom_resource = build :custom_resource, max_value: 5, reset_direction: 0, resets: { 'long' => -1 }

      expect(custom_resource.refreshed_value(3, 'long')).to eq 0
    end

    it 'resets to max on a full reset when reset_direction is 1' do
      custom_resource = build :custom_resource, max_value: 5, reset_direction: 1, resets: { 'long' => -1 }

      expect(custom_resource.refreshed_value(2, 'long')).to eq 5
    end

    it 'leaves the value untouched for a cadence key that is 0 or absent', :aggregate_failures do
      custom_resource = build :custom_resource, max_value: 5, reset_direction: 1, resets: { 'long' => 0 }

      expect(custom_resource.refreshed_value(2, 'long')).to eq 2
      expect(custom_resource.refreshed_value(2, 'session')).to eq 2
    end

    it 'applies a partial change clamped to 0/max depending on reset_direction', :aggregate_failures do
      up = build :custom_resource, max_value: 5, reset_direction: 0, resets: { 'short' => 2 }
      down = build :custom_resource, max_value: 5, reset_direction: 1, resets: { 'short' => 2 }

      expect(up.refreshed_value(4, 'short')).to eq 2 # counts usages up; clamped at 0
      expect(down.refreshed_value(4, 'short')).to eq 5 # counts remaining down; clamped at max
    end

    # Ticket C8 (TLC subclass resources): no TLC rest command exists yet to
    # exercise a real "short rest"/"long rest" HTTP action for a Tlc::Character
    # (C1, ticket #17, is Blocked). This proves #refreshed_value is not a
    # second, competing reset algorithm: given the same custom_resource and
    # starting value, it produces IDENTICAL output to the actually-shipped
    # CharactersContext::Dnd2024 rest commands' inline refresh_resources logic.
    describe 'parity with the shipped dnd2024 rest commands' do
      let!(:character) do
        create :character, :dnd2024, data: {
          spent_spell_slots: {}, hit_dice: {}, spent_hit_dice: {}, health: { max: 10, current: 5 }
        }
      end
      let!(:custom_resource) do
        create :custom_resource, resourceable: character, max_value: 4, reset_direction: 1,
                                 resets: { 'short' => -1, 'long' => -1 }
      end
      let!(:resource) { create :character_resource, character: character, custom_resource: custom_resource, value: 0 }

      it 'matches the short rest command output' do
        expected = custom_resource.refreshed_value(0, 'short')

        CharactersContext::Dnd2024::MakeShortRestCommand.new.call(character: Dnd2024::Character.find(character.id))

        expect(resource.reload.value).to eq(expected)
      end

      it 'matches the long rest command output' do
        expected = custom_resource.refreshed_value(0, 'long')

        CharactersContext::Dnd2024::MakeLongRestCommand.new.call(character: Dnd2024::Character.find(character.id))

        expect(resource.reload.value).to eq(expected)
      end
    end
  end
end
