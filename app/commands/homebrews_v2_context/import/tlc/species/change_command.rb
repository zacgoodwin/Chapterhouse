# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Species
        # Updates a Tlc::Homebrews::Species: re-saves the species-level info,
        # appends any brand-new traits, and prunes trait rows the payload dropped.
        # Mirrors Import::Dnd2024::Races::ChangeCommand (existing-trait edits stay
        # deferred there too — a full trait diff is out of this ticket's scope).
        class ChangeCommand < BaseCommand
          private

          def do_prepare(input)
            input[:existing_traits] =
              ::Tlc::Feat
                .where(origin: 'species', origin_value: input[:species].id)
                .index_by(&:id)
          end

          def do_persist(input)
            ActiveRecord::Base.transaction do
              input[:species].update!(input.slice(:title, :description, :public, :info))

              if input[:traits]
                add_new_traits(input)
                remove_dropped_traits(input)
              end
            end

            { result: :ok }
          end

          def add_new_traits(input)
            input[:traits].each do |trait|
              next if trait[:id] && input[:existing_traits][trait[:id]]

              add_feat.call(
                trait.except(:id).merge({
                  user: input[:user],
                  origin: 'species',
                  origin_value: input[:species].id,
                  level: trait.fetch(:level, 1)
                })
              )
            end
          end

          def remove_dropped_traits(input)
            ::Tlc::Feat
              .where(origin: 'species', origin_value: input[:species].id)
              .where(id: input[:existing_traits].keys - input[:traits].pluck(:id)).destroy_all
          end

          def add_feat = HomebrewsV2Context::Import::Tlc::Feats::AddCommand.new
        end
      end
    end
  end
end
