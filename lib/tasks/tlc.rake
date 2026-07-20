# frozen_string_literal: true

namespace :tlc do
  desc 'Idempotently seed TLC homebrew content from db/data/tlc/*.json (set TLC_SEED_DIR to override).'
  task seed: :environment do
    dir = ENV.fetch('TLC_SEED_DIR', Rails.root.join('db/data/tlc').to_s)
    Tlc::Seeder.call(dir: dir)
  end
end
