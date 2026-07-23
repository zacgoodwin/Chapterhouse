# frozen_string_literal: true

# Gate against malformed seed slugs: upstream shipped a Cyrillic homoglyph
# ("stoneсunning") and five slugs with spaces ("boon of recovery"), repaired
# by migration 20260722090000. Every slug in the seed JSON must match the
# canonical shape so a reintroduced homoglyph or spaced slug REDs at commit
# time instead of silently seeding an unmatchable record.
describe 'seed JSON slug contract (db/data)' do # rubocop: disable RSpec/DescribeClass
  it 'slugs are lowercase ASCII with underscores', :aggregate_failures do
    Rails.root.glob('db/data/**/*.json').each do |file|
      raw = file.read
      next if raw.strip.empty? # empty book stubs

      rows = JSON.parse(raw)
      rows = [rows] unless rows.is_a?(Array)
      rows.each do |row|
        slug = row['slug'] if row.is_a?(Hash)
        expect(slug).to(match(/\A[a-z0-9_-]+\z/), "#{file}: #{slug.inspect}") if slug
      end
    end
  end
end
