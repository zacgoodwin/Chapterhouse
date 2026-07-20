# frozen_string_literal: true

module Adminbook
  module Tlc
    class SpellsController < ContentController
      private

      def model_class = ::Tlc::Spell
      def param_key = :spell

      def permitted_keys
        [:slug, :data, :visibility, :verified, { name: %i[en ru] }]
      end

      # `data` is the spell's meta column too; visibility/verified fold in after
      # this raw assignment (see ContentController#persist).
      def transform(attrs)
        attrs['data'] = parse_json(attrs['data']) if attrs.key?('data')
        attrs
      end
    end
  end
end
