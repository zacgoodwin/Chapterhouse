# frozen_string_literal: true

module HomebrewsV2
  module Tlc
    class SubclassSerializer < ApplicationSerializer
      # info carries class_id + the C8-shaped resources array. Class display-name
      # resolution is a parked D-phase concern (Tlc::Character does not inherit
      # Dnd2024::Character.classes_info), so it is intentionally not computed here.
      attributes :id, :features, :info

      def features
        return [] unless context
        return [] unless context[:features]

        relation = context[:features]
        Panko::ArraySerializer.new(
          relation,
          each_serializer: HomebrewsV2::Tlc::FeatSerializer
        ).serialize(relation)
      end
    end
  end
end
