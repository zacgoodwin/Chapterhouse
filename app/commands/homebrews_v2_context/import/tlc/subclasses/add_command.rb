# frozen_string_literal: true

module HomebrewsV2Context
  module Import
    module Tlc
      module Subclasses
        # Creates a Tlc::Homebrews::Subclass container (info carries class_id +
        # C8-shaped resources) plus one Tlc::Feat row per feature (origin
        # 'subclass', origin_value = subclass.id, conditions.level = feature level)
        # so RefreshFeats attaches each feature at its subclass level.
        class AddCommand < BaseCommand
          private

          def do_persist(input)
            result = ActiveRecord::Base.transaction do
              subclass = ::Tlc::Homebrews::Subclass.create!(input.slice(:user, :title, :description, :public, :info))
              input[:features]&.each do |feature|
                add_feat.call(
                  feature.except(:id).merge({
                    user: input[:user],
                    origin: 'subclass',
                    origin_value: subclass.id,
                    level: feature.fetch(:level, 1)
                  })
                )
              end
              subclass
            end

            { result: result }
          end

          def add_feat = HomebrewsV2Context::Import::Tlc::Feats::AddCommand.new
        end
      end
    end
  end
end
