# frozen_string_literal: true

module Adminbook
  module Tlc
    class ItemsController < ContentController
      private

      def model_class = ::Tlc::Item
      def param_key = :item

      def permitted_keys
        [
          :slug, :kind, :modifiers, :visibility, :verified,
          { name: %i[en ru], description: %i[en ru] }
        ]
      end

      def transform(attrs)
        attrs['modifiers'] = parse_json(attrs['modifiers']) if attrs.key?('modifiers')
        attrs
      end
    end
  end
end
