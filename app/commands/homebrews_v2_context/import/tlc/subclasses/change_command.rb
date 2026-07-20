# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Subclasses
        # Updates a Tlc::Homebrews::Subclass: re-saves info (class_id + resources),
        # appends new features, prunes dropped ones. Mirrors
        # Import::Dnd2024::Subclasses::ChangeCommand.
        class ChangeCommand < BaseCommand
          private

          def do_prepare(input)
            input[:existing_features] =
              ::Tlc::Feat
                .where(origin: 'subclass', origin_value: input[:subclass].id)
                .index_by(&:id)
          end

          def do_persist(input)
            ActiveRecord::Base.transaction do
              input[:subclass].update!(input.slice(:title, :description, :public, :info))

              if input[:features]
                add_new_features(input)
                remove_dropped_features(input)
              end
            end

            { result: :ok }
          end

          def add_new_features(input)
            input[:features].each do |feature|
              next if feature[:id] && input[:existing_features][feature[:id]]

              add_feat.call(
                feature.except(:id).merge({
                  user: input[:user],
                  origin: 'subclass',
                  origin_value: input[:subclass].id,
                  level: feature.fetch(:level, 1)
                })
              )
            end
          end

          def remove_dropped_features(input)
            ::Tlc::Feat
              .where(origin: 'subclass', origin_value: input[:subclass].id)
              .where(id: input[:existing_features].keys - input[:features].pluck(:id)).destroy_all
          end

          def add_feat = HomebrewsV2Context::Import::Tlc::Feats::AddCommand.new
        end
      end
    end
  end
end
