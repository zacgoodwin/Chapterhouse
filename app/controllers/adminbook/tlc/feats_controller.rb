# frozen_string_literal: true

module Adminbook
  module Tlc
    class FeatsController < ContentController
      private

      def model_class = ::Tlc::Feat
      def param_key = :feat

      # No eval_variables / description_eval_variables / bonus_eval_variables:
      # the three Ruby-eval'd feat fields are absent by design (T18).
      def permitted_keys
        [
          :slug, :origin, :origin_value, :kind, :limit_refresh, :exclude,
          :conditions, :price, :continious, :visibility, :verified,
          { title: %i[en ru], description: %i[en ru] }
        ]
      end

      def transform(attrs)
        attrs['conditions'] = parse_json(attrs['conditions']) if attrs.key?('conditions')
        attrs['price'] = parse_json(attrs['price']) if attrs.key?('price')
        attrs['exclude'] = attrs['exclude'].to_s.split(',') if attrs.key?('exclude')
        attrs['limit_refresh'] = nil if attrs['limit_refresh'].blank?
        attrs
      end
    end
  end
end
