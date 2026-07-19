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
      en: spell[2],
      ru: spell[3]
    },
    data: {
      level: spell[0].to_i,
      school: spell[4],
      available_for: spell[6].split(','),
      source: spell[5]
    },
    available_for: spell[6].split(',')
  }
end
Dnd5::Spell.upsert_all(spells)

items = CSV.parse(File.read(Rails.root.join('db/data/dnd5/items.csv')), headers: false, col_sep: ';')
items.map! do |item|
  {
    kind: item[0],
    slug: item[1],
    name: {
      en: item[2],
      ru: item[3]
    },
    data: {
      price: item[4].to_i,
      weight: item[5].to_f
    }
  }
end
Dnd5::Item.upsert_all(items)

items = CSV.parse(File.read(Rails.root.join('db/data/daggerheart/items.csv')), headers: false, col_sep: ';')
items.map! do |item|
  {
    kind: item[0],
    slug: item[1],
    name: {
      en: item[2],
      ru: item[3]
    }
  }
end
Daggerheart::Item.upsert_all(items)

# виды урона оружия
# колющий - pierce
# рубящий - slash
# дробящий - bludge

# свойства оружия
# ближний бой - melee
# метательное - thrown
# дальний бой - range

# фехтовальное - finesse
# лёгкое - light
# тяжёлое - heavy
# универсальное - versatile
# двуручное - 2handed
# досягаемость - reach
# перезарядка - reload

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

Dir[File.join(Rails.root.join('db/data/daggerheart/feats/*.json'))].each do |filename|
  puts "seeding - #{filename}"
  JSON.parse(File.read(filename)).each do |feat|
    ::Daggerheart::Feat.create!(feat)
  end
end

markdown = ActiveMarkdown.new
file_content = File.read(Rails.root.join('db/data/dc20/spells.json'))
feats = JSON.parse(file_content)
feats.each do |feat|
  feat['info']['enhancements'].map! do |item|
    item['description'].transform_values! { |value| markdown.call(value: value).strip }
    item
  end
  ::Dc20::Feat.create!(feat)
end

file_content = File.read(Rails.root.join('db/data/dc20/maneuvers.json'))
feats = JSON.parse(file_content)
feats.each do |feat|
  feat['info']['enhancements'].map! do |item|
    item['description'].transform_values! { |value| markdown.call(value: value).strip }
    item
  end
  ::Dc20::Feat.create!(feat)
end

Dir[File.join(Rails.root.join('db/data/fallout/perks/*.json'))].each do |filename|
  puts "seeding - #{filename}"
  JSON.parse(File.read(filename)).each do |feat|
    ::Fallout::Feat.create!(feat)
  end
end

psychic_blades_feat = ::Dnd5::Feat.find_by(slug: 'psychic_blades')
if psychic_blades_feat
  Dnd5::Item.create!(
    slug: 'psychic_blades',
    kind: 'weapon',
    name: { en: 'Psychic Blades', ru: 'Психические клинки' },
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

Dir[File.join(Rails.root.join('db/data/fallout/weapons.json'))].each do |filename|
  puts "seeding - #{filename}"
  weapons = JSON.parse(File.read(filename))
  Fallout::Item.upsert_all(weapons) if weapons.any?
end

weapons_file = File.read(Rails.root.join('db/data/dc20/weapons.json'))
weapons = JSON.parse(weapons_file)
Dc20::Item.upsert_all(weapons) if weapons.any?

armor_file = File.read(Rails.root.join('db/data/dc20/armor.json'))
armor = JSON.parse(armor_file)
Dc20::Item.upsert_all(armor) if armor.any?

shield_file = File.read(Rails.root.join('db/data/dc20/shield.json'))
shield = JSON.parse(shield_file)
Dc20::Item.upsert_all(shield) if shield.any?

weapons_file = File.read(Rails.root.join('db/data/dnd5/weapons.json'))
weapons = JSON.parse(weapons_file)
Dnd5::Item.upsert_all(weapons) if weapons.any?

armor_file = File.read(Rails.root.join('db/data/dnd5/armor.json'))
armor = JSON.parse(armor_file)
Dnd5::Item.upsert_all(armor) if armor.any?

armor_file = File.read(Rails.root.join('db/data/daggerheart/armor.json'))
armor = JSON.parse(armor_file)
Daggerheart::Item.upsert_all(armor) if armor.any?

weapons_file = File.read(Rails.root.join('db/data/daggerheart/weapons.json'))
weapons = JSON.parse(weapons_file)
Daggerheart::Item.upsert_all(weapons) if weapons.any?

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

file_content = File.read(Rails.root.join('db/data_prod/daggerheart/feats.json'))
JSON.parse(file_content).each do |item|
  feat = Daggerheart::Feat.find_by(slug: item['slug'])
  next unless feat

  feat.update!(item.slice('description', 'kind', 'limit_refresh', 'description_eval_variables', 'eval_variables', 'continious', 'bonus_eval_variables', 'price', 'modifiers', 'tokens'))
end

load Rails.root.join('db/seeds_prod.rb')
