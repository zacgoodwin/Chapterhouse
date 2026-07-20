# frozen_string_literal: true

module HomebrewsV2
  module Tlc
    class SpeciesSerializer < ApplicationSerializer
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
