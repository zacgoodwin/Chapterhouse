# frozen_string_literal: true

module Adminbook
  module Tlc
    # Shared CRUD skeleton for the TLC content admin (feats/spells/items).
    #
    # Two invariants live here, not in the per-type subclasses:
    #   1. Ruby-eval'd fields are NEVER in a subclass's `permitted_keys`, so they
    #      cannot be written through this admin path (T18 / eng finding 6: the
    #      base Adminbook::FeatsController permits eval_variables etc., an
    #      RCE-by-design surface kept seed-only for TLC). The exclusion is the
    #      absence of those keys — there is nothing to strip.
    #   2. visibility + verified are dedicated controls that fold into the row's
    #      jsonb meta column via the model setters, applied AFTER the content
    #      attributes so they win over any meta a raw jsonb textarea carried.
    class ContentController < Adminbook::BaseController
      def index
        @records = index_scope
      end

      def new
        @record = model_class.new
      end

      def edit
        @record = model_class.find(params.expect(:id))
      end

      def create
        persist(model_class.new)
      end

      def update
        persist(model_class.find(params.expect(:id)))
      end

      def destroy
        model_class.find(params.expect(:id)).destroy
        redirect_to action: :index
      end

      private

      # `?verified=false` narrows the list to the human-verification queue.
      def index_scope
        scope = model_class.order(created_at: :desc)
        params[:verified] == 'false' ? scope.where_verified(false) : scope
      end

      def persist(record)
        record.assign_attributes(content_attributes)
        record.visibility = visibility_param if visibility_param
        record.verified = verified_param
        record.save
        redirect_to action: :index
      end

      def content_attributes
        transform(permitted.except(:visibility, :verified).to_h)
      end

      def visibility_param
        permitted[:visibility].presence
      end

      def verified_param
        permitted[:verified]
      end

      def permitted
        @permitted ||= params.expect(param_key => permitted_keys)
      end

      # Textareas post JSON in the codebase's admin dialect (Ruby-hash `=>`/`nil`
      # tolerated), matching the other adminbook controllers' transform.
      def parse_json(value)
        JSON.parse(value.to_s.gsub(' =>', ':').gsub('nil', 'null'))
      end
    end
  end
end
