# frozen_string_literal: true

require 'csv'

# Gate tests for the db/data/dnd5 CSV column contract that db/seeds.rb indexes
# into. The english-only conversion dropped the RU name column, shifting every
# index left: spells are now [0 level, 1 slug, 2 en name, 3 school, 4 source,
# 5 classes]; items are [0 kind, 1 slug, 2 en name, 3 price, 4 weight].
# Pure data/shape checks against the real CSVs -- a re-added or re-ordered
# column REDs here before `rails db:seed` can silently write names into
# schools or prices. Domain sets mirror the current data, checked 2026-07-22.
describe 'dnd5 seed CSV column contract (db/data/dnd5)' do # rubocop: disable RSpec/DescribeClass
  let(:spells) { CSV.parse(Rails.root.join('db/data/dnd5/spells.csv').read, headers: false, col_sep: ';') }
  let(:items) { CSV.parse(Rails.root.join('db/data/dnd5/items.csv').read, headers: false, col_sep: ';') }

  let(:schools) { %w[abjuration conjuration divination enchantment evocation illusion necromancy transmutation] }
  let(:classes) { %w[artificer bard cleric druid paladin ranger sorcerer warlock wizard] }
  let(:item_kinds) { %w[ammo focus item music potion tools] }

  it 'spells.csv rows are [level, slug, en name, school, source, classes]', :aggregate_failures do
    expect(spells.size).to be > 400

    spells.each do |row|
      expect(row.size).to eq(6), "#{row[1]}: expected 6 columns, got #{row.size}"
      expect(row[0]).to match(/\A\d\z/), "#{row[1]}: level column is #{row[0].inspect}"
      expect(row[1]).to match(/\A[a-z0-9_-]+\z/), "slug column is #{row[1].inspect}"
      expect(row[2]).to be_present.and(satisfy(&:ascii_only?)), "#{row[1]}: en name column is #{row[2].inspect}"
      expect(schools).to include(row[3]), "#{row[1]}: school column is #{row[3].inspect}"
      expect(row[4]).to match(/\A[A-Z][A-Za-z]*\z/), "#{row[1]}: source column is #{row[4].inspect}"
      expect(row[5].split(',')).to all(be_in(classes)), "#{row[1]}: classes column is #{row[5].inspect}"
    end
  end

  it 'items.csv rows are [kind, slug, en name, price, weight]', :aggregate_failures do
    expect(items.size).to be > 100

    items.each do |row|
      expect(row.size).to eq(5), "#{row[1]}: expected 5 columns, got #{row.size}"
      expect(item_kinds).to include(row[0]), "#{row[1]}: kind column is #{row[0].inspect}"
      expect(row[1]).to match(/\A[a-z0-9_-]+\z/), "slug column is #{row[1].inspect}"
      expect(row[2]).to be_present.and(satisfy(&:ascii_only?)), "#{row[1]}: en name column is #{row[2].inspect}"
      expect(row[3]).to match(/\A\d+\z/), "#{row[1]}: price column is #{row[3].inspect}"
      expect(row[4]).to match(/\A\d+(\.\d+)?\z/), "#{row[1]}: weight column is #{row[4].inspect}"
    end
  end
end
