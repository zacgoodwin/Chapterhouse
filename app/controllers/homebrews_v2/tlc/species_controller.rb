# frozen_string_literal: true

module HomebrewsV2
  module Tlc
    class SpeciesController < HomebrewsV2::HomebrewController
      include SerializeResource

      private

      def class_name = ::Tlc::Homebrews::Species
      def serializer = ::HomebrewsV2::Tlc::SpeciesSerializer
      def feat_class = ::Tlc::Feat
      def character_class = ::Tlc::Character

      def find_existing_characters
        return unless characters_relation.exists?(["data ->> 'species' = ?", @element.id])

        @kept = true
      end
    end
  end
end
