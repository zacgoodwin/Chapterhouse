# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Species
        # Creates a Tlc::Homebrews::Species container plus one Tlc::Feat row per
        # trait (origin 'species', origin_value = species.id). trait_kind ('base'
        # or 'optional') rides through Feats::AddCommand into the row's info so the
        # picker (D2) can split the fixed base traits from the choose-N pool.
        # No dnd_names cache push: TLC has no homebrew-name lookup consumer yet
        # (Tlc::Character lacks Dnd2024::Character#species_name; that resolution is
        # a parked D-phase display concern), and dnd_names is dnd2024-keyed.
        class AddCommand < BaseCommand
          private

          def do_persist(input)
            result = ActiveRecord::Base.transaction do
              species = ::Tlc::Homebrews::Species.create!(input.slice(:user, :title, :description, :public, :info))
              input[:traits]&.each { |trait| add_trait(trait, input[:user], species.id) }
              species
            end

            { result: result }
          end

          def add_trait(trait, user, species_id)
            add_feat.call(
              trait.except(:id).merge({
                user: user,
                origin: 'species',
                origin_value: species_id,
                level: trait.fetch(:level, 1)
              })
            )
          end

          def add_feat = HomebrewsV2Context::Import::Tlc::Feats::AddCommand.new
        end
      end
    end
  end
end
