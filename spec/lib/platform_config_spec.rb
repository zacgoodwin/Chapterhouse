# frozen_string_literal: true

describe PlatformConfig do
  # Acceptance criterion 1 against the real tlc.json: it declares base:dnd2024
  # and carries no `skills` key, so the merged config inherits dnd2024's skills.
  describe 'the shipped tlc.json' do
    it 'declares dnd2024 as its base and overrides no skills', :aggregate_failures do
      raw = described_class.send(:read_config, 'tlc')

      expect(raw['base']).to eq('dnd2024')
      expect(raw).not_to have_key('skills')
    end

    it 'inherits keys that tlc.json omits from the dnd2024 base' do
      expect(described_class.data('tlc')['skills']).to eq(described_class.data('dnd2024')['skills'])
    end

    it 'drops the base directive from the merged result' do
      expect(described_class.data('tlc')).not_to have_key('base')
    end
  end

  # Merge semantics on controlled configs, so the assertions do not depend on
  # tlc.json's evolving content.
  describe 'base deep-merge' do
    before do
      allow(described_class).to receive(:read_config).with('dnd2024').and_return(base_config)
      allow(described_class).to receive(:read_config).with('tlc').and_return(tlc_config)
    end

    let(:base_config) {
      { 'skills' => { 'stealth' => 'base' }, 'only_base' => 'base', 'shared' => 'base' }
    }

    context 'when tlc overrides a top-level key' do
      let(:tlc_config) { { 'base' => 'dnd2024', 'shared' => 'tlc' } }

      it 'the tlc value wins for that key while siblings inherit', :aggregate_failures do
        result = described_class.data('tlc')

        expect(result['shared']).to eq('tlc')     # overridden
        expect(result['only_base']).to eq('base') # untouched sibling inherits
        expect(result['skills']).to eq('stealth' => 'base')
      end
    end

    context 'when tlc adds a nested key' do
      let(:tlc_config) { { 'base' => 'dnd2024', 'skills' => { 'arcana' => 'tlc' } } }

      it 'deep-merges the nested hash instead of replacing it' do
        expect(described_class.data('tlc')['skills']).to eq('stealth' => 'base', 'arcana' => 'tlc')
      end
    end
  end

  # memoization-in-cache: with a real store the merge computes once per cache
  # window; a version change is a fresh key, which is why a tlc.json edit needs a
  # version bump or cache clear to surface.
  describe 'cache memoization' do
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(described_class).to receive(:read_config).and_call_original
    end

    it 'reads each provider config once per cache window', :aggregate_failures do
      2.times { described_class.data('tlc') }

      expect(described_class).to have_received(:read_config).with('tlc').once
      expect(described_class).to have_received(:read_config).with('dnd2024').once
    end

    it 'recomputes under a different version (distinct cache key)' do
      described_class.data('tlc', version: 'a')
      described_class.data('tlc', version: 'b')

      expect(described_class).to have_received(:read_config).with('tlc').twice
    end
  end
end
