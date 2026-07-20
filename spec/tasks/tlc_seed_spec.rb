# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# Gate tests for `rake tlc:seed` / Tlc::Seeder (ticket B1). Each acceptance
# criterion from the plan is asserted as written. Fixtures are written to a
# throwaway dir per example, so no committed fixture files and no cross-test
# bleed; DB rows roll back with the transactional fixture wrapper.
describe Tlc::Seeder do # rubocop:disable RSpec/SpecFilePathFormat -- ticket B1 mandates spec/tasks/tlc_seed_spec.rb
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def write_rows(stem, rows)
    File.write(File.join(@dir, "#{stem}.json"), JSON.generate(rows))
  end

  def seed(out: StringIO.new)
    described_class.call(dir: @dir, out: out)
  end

  let(:valid_feat) do
    {
      'slug' => 'stoneheart', 'title' => { 'en' => 'Stoneheart' },
      'description' => { 'en' => 'Your skin is stone.' },
      'origin' => 'species', 'origin_value' => 'turtlefolk', 'kind' => 'static',
      'modifiers' => { 'armor_class' => { 'type' => 'set', 'value' => '13 + con' } }
    }
  end

  # Lady of Ivory to Fabricate: a subclass feat that auto-grants a banned spell.
  let(:fabricate_grant) do
    valid_feat.merge(
      'slug' => 'lady_of_ivory', 'origin' => 'subclass', 'origin_value' => 'lady_of_ivory',
      'info' => { 'static_spells' => { 'fabricate' => {} } }
    )
  end

  describe 'idempotency (acceptance test 9)' do
    it 'produces identical row counts across two runs', :aggregate_failures do
      write_rows('feats', [valid_feat])
      write_rows('spells', [])

      seed
      first = Feat.tlc.count
      seed
      second = Feat.tlc.count

      expect(first).to eq(1)
      expect(second).to eq(1)
    end
  end

  describe 'banned-grant lint (decision 23)' do
    it 'aborts naming the slug and banned spell, writing nothing, when no exemption', :aggregate_failures do
      write_rows('feats', [fabricate_grant])

      expect { seed }.to raise_error(described_class::BannedGrantError, /lady_of_ivory.*fabricate/i)
      expect(Feat.tlc.count).to eq(0)
    end

    it 'seeds successfully when banned_exemption is true', :aggregate_failures do
      write_rows('feats', [fabricate_grant.merge('banned_exemption' => true)])

      expect { seed }.not_to raise_error
      expect(Feat.tlc.where(slug: 'lady_of_ivory').count).to eq(1)
    end

    it 'also catches the eval_variables.static_spells merge form' do
      row = valid_feat.merge(
        'slug' => 'eval_grant',
        'eval_variables' => { 'static_spells' => "static_spells.merge({ 'teleport': { 'save_dc': 15 } })" }
      )
      write_rows('feats', [row])

      expect { seed }.to raise_error(described_class::BannedGrantError, /teleport/)
    end

    it 'does not false-positive on an allowed slug containing a banned one as a substring', :aggregate_failures do
      row = valid_feat.merge('slug' => 'circler', 'info' => { 'static_spells' => { 'teleportation_circle' => {} } })
      write_rows('feats', [row])

      expect { seed }.not_to raise_error
      expect(Feat.tlc.count).to eq(1)
    end
  end

  describe 'malformed JSON' do
    it 'aborts loudly with JSON::ParserError (not rescued, dev sees the stacktrace)' do
      File.write(File.join(@dir, 'feats.json'), '[ { "slug": "broken" ')

      expect { seed }.to raise_error(JSON::ParserError)
    end
  end

  describe 'summary output' do
    it 'prints per-type counts and the verified:false count on every run', :aggregate_failures do
      write_rows('feats', [valid_feat, valid_feat.merge('slug' => 'garbled_perk', 'verified' => false)])
      out = StringIO.new

      result = seed(out: out)

      expect(out.string).to match(/feats\s+2/)
      expect(out.string).to match(/unverified rows\s+1/)
      expect(result).to eq(counts: { 'feats' => 2 }, unverified: 1)
    end
  end

  describe 'spell and item rows' do
    it 'seeds Tlc::Spell and Tlc::Item, folding meta into the right jsonb column', :aggregate_failures do
      write_rows('spells', [{ 'slug' => 'tlc_ward', 'title' => { 'en' => 'Ward' }, 'verified' => false }])
      write_rows('items', [{ 'slug' => 'leyfarers_journal', 'title' => { 'en' => 'Journal' }, 'kind' => 'gear' }])

      seed
      spell = Spell.tlc.find_by(slug: 'tlc_ward')
      item = Item.tlc.find_by(slug: 'leyfarers_journal')

      expect(spell.data['verified']).to be(false)
      expect(item.info['verified']).to be(true)
      expect(item.kind).to eq('gear')
    end

    it 'upserts spells and items idempotently against their partial unique index', :aggregate_failures do
      write_rows('spells', [{ 'slug' => 'tlc_ward', 'title' => { 'en' => 'Ward' } }])
      write_rows('items', [{ 'slug' => 'emblem', 'title' => { 'en' => 'Emblem' }, 'kind' => 'gear' }])

      2.times { seed }

      expect(Spell.tlc.count).to eq(1)
      expect(Item.tlc.count).to eq(1)
    end
  end

  describe 'missing files' do
    it 'is a no-op when a stem file is absent', :aggregate_failures do
      expect { seed }.not_to raise_error
      expect(Feat.tlc.count).to eq(0)
    end
  end

  describe 'rake tlc:seed wiring' do
    before { Rails.application.load_tasks unless Rake::Task.task_defined?('tlc:seed') }

    after { Rake::Task['tlc:seed'].reenable }

    it 'invokes Tlc::Seeder against TLC_SEED_DIR' do
      allow(described_class).to receive(:call)
      ENV['TLC_SEED_DIR'] = @dir

      Rake::Task['tlc:seed'].invoke

      expect(described_class).to have_received(:call).with(dir: @dir)
    ensure
      ENV.delete('TLC_SEED_DIR')
    end
  end
end
