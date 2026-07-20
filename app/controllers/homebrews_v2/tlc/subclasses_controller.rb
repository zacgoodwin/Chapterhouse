# frozen_string_literal: true

module HomebrewsV2
  module Tlc
    class SubclassesController < HomebrewsV2::HomebrewController
      include SerializeResource

      private

      def class_name = ::Tlc::Homebrews::Subclass
      def serializer = ::HomebrewsV2::Tlc::SubclassSerializer
      def feat_class = ::Tlc::Feat
      def character_class = ::Tlc::Character

      def find_existing_characters
        subclasses = character_class.pluck(:data).pluck(:subclasses)
        return if subclasses.flat_map(&:values).exclude?(@element.id)

        @kept = true
      end
    end
  end
end
