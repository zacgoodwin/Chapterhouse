# frozen_string_literal: true

describe Tlc::PointBuy do
  describe '.spent' do
    it 'prices the PH p.38 table, including the 2-point 13->14 and 14->15 steps', :aggregate_failures do
      expect(described_class::COST).to eq(8 => 0, 9 => 1, 10 => 2, 11 => 3, 12 => 4, 13 => 5, 14 => 7, 15 => 9)
      expect(described_class::BUDGET).to eq(27)
      expect(described_class.spent(str: 8, dex: 8, con: 8, int: 8, wis: 8, cha: 8)).to eq(0)
      # The standard array, the reference 27-point spread.
      expect(described_class.spent(str: 15, dex: 14, con: 13, int: 12, wis: 10, cha: 8)).to eq(27)
      # Three 15s cost exactly 27 -- lopsided but legal. The fourth is what breaks it.
      expect(described_class.spent(str: 15, dex: 15, con: 15, int: 8, wis: 8, cha: 8)).to eq(27)
      expect(described_class.spent(str: 15, dex: 15, con: 15, int: 15, wis: 8, cha: 8)).to eq(36)
      # The 13->14 and 14->15 steps cost 2, not 1: six 13s fit, six 14s do not.
      expect(described_class.spent(str: 13, dex: 13, con: 13, int: 13, wis: 13, cha: 8)).to eq(25)
      expect(described_class.spent(str: 14, dex: 14, con: 8, int: 8, wis: 8, cha: 8)).to eq(14)
    end

    it 'reads string scores, since JSONB round-trips them' do
      expect(described_class.spent('str' => '15', 'dex' => '14', 'con' => '13', 'int' => '12', 'wis' => '10', 'cha' => '8'))
        .to eq(27)
    end

    it 'returns nil for a score off the table, never a free 0', :aggregate_failures do
      expect(described_class.spent(str: 16, dex: 8, con: 8, int: 8, wis: 8, cha: 8)).to be_nil
      expect(described_class.spent(str: 7, dex: 8, con: 8, int: 8, wis: 8, cha: 8)).to be_nil
    end
  end

  describe '.affordable?' do
    it 'allows a spread at or under budget and rejects everything else', :aggregate_failures do
      expect(described_class.affordable?(str: 15, dex: 14, con: 13, int: 12, wis: 10, cha: 8)).to be(true)
      # Under-spending is legal by RAW: 27 points to spend, not 27 to burn.
      expect(described_class.affordable?(str: 8, dex: 8, con: 8, int: 8, wis: 8, cha: 8)).to be(true)
      expect(described_class.affordable?(str: 15, dex: 15, con: 15, int: 8, wis: 8, cha: 8)).to be(true)
      expect(described_class.affordable?(str: 15, dex: 15, con: 15, int: 15, wis: 8, cha: 8)).to be(false)
      expect(described_class.affordable?(str: 20, dex: 8, con: 8, int: 8, wis: 8, cha: 8)).to be(false)
    end
  end
end
