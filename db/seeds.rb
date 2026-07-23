# frozen_string_literal: true

# Deterministic content seeding for a fresh database. Every input file is
# checked into db/data/** or db/data_prod/**; run once via `rails db:seed`
# after `rails db:schema:load`. One-off ETL scratch that used to live here
# is in git history (pre-Supabase seeds.rb).

require 'csv'

spells = CSV.parse(File.read(Rails.root.join('db/data/dnd5/spells.csv')), headers: false, col_sep: ';')
spells.map! do |spell|
  {
    type: 'Dnd5::Spell',
    slug: spell[1],
    name: {
      en: spell[2]
    },
    data: {
      level: spell[0].to_i,
      school: spell[3],
      available_for: spell[5].split(','),
      source: spell[4]
    },
    available_for: spell[5].split(',')
  }
end
Dnd5::Spell.upsert_all(spells)

items = CSV.parse(File.read(Rails.root.join('db/data/dnd5/items.csv')), headers: false, col_sep: ';')
items.map! do |item|
  {
    kind: item[0],
    slug: item[1],
    name: {
      en: item[2]
    },
    data: {
      price: item[3].to_i,
      weight: item[4].to_f
    }
  }
end
Dnd5::Item.upsert_all(items)

# weapon damage kinds: pierce, slash, bludge
# weapon properties: melee, thrown, range,
#   finesse, light, heavy, versatile, 2handed, reach, reload

Dir[File.join(Rails.root.join('db/data/dnd5/features/*.json'))].each do |filename|
  puts "seeding - #{filename}"
  JSON.parse(File.read(filename)).each do |feat|
    ::Dnd5::Feat.create!(feat)
  end
end

Dir[File.join(Rails.root.join('db/data/dnd2024/features/*.json'))].each do |filename|
  puts "seeding - #{filename}"
  JSON.parse(File.read(filename)).each do |feat|
    ::Dnd2024::Feat.create!(feat)
  end
end

# dnd2024 spells are Feat records with origin "spell" (origin 6), served by
# Frontend::Dnd2024::SpellsController; the spells table is dnd5-only
puts 'seeding - db/data/dnd2024/spells.json'
JSON.parse(File.read(Rails.root.join('db/data/dnd2024/spells.json'))).each do |spell|
  ::Dnd2024::Feat.create!(spell)
end

psychic_blades_feat = ::Dnd5::Feat.find_by(slug: 'psychic_blades')
if psychic_blades_feat
  Dnd5::Item.create!(
    slug: 'psychic_blades',
    kind: 'weapon',
    name: { en: 'Psychic Blades' },
    data: {},
    info: {
      weapon_skill: 'light',
      type: 'thrown',
      dist: '60/120',
      damage: '1d6',
      damage_type: 'psychic',
      caption: ['finesse'],
      mastery: 'vex'
    },
    itemable: psychic_blades_feat
  )
end

weapons_file = File.read(Rails.root.join('db/data/dnd5/weapons.json'))
weapons = JSON.parse(weapons_file)
Dnd5::Item.upsert_all(weapons) if weapons.any?

armor_file = File.read(Rails.root.join('db/data/dnd5/armor.json'))
armor = JSON.parse(armor_file)
Dnd5::Item.upsert_all(armor) if armor.any?

Item::Recipe.create(
  tool: Dnd5::Item.find_by(slug: 'herbalism'),
  item: Dnd5::Item.find_by(slug: 'potion_healing'),
  info: { output_per_day: 1 }
)

file_content = File.read(Rails.root.join('db/data/dnd2024/spells_v2.json'))
spells = JSON.parse(file_content)
spells.each do |spell|
  feat = ::Dnd2024::Feat.where(origin: 6).find_by(slug: spell['slug'])
  next unless feat

  feat.update(title: spell['title'])
end
