# frozen_string_literal: true

module Frontend
  class ItemsController < Frontend::BaseController
    include Deps[feature_requirement: 'feature_requirement']
    include SerializeRelation

    def index
      serialize_relation_v2(items.visible.kept, ::ItemSerializer, :items, cache_options: cache_options)
    end

    private

    def cache_options
      return {} unless feature_requirement.call(current: params[:version], initial: '0.3.26')
      return {} if params[:homebrew]

      { key: "items/#{params[:provider]}/#{I18n.locale}/v6", expires_in: 12.hours }
    end

    def items
      if feature_requirement.call(current: params[:version], initial: '0.3.26')
        if params[:homebrew]
          relation.where(user_id: current_user.id)
        else
          relation.where(user_id: nil)
        end
      else
        relation.where(user_id: [nil, current_user.id])
      end
    end

    def relation
      case params[:provider]
      when 'dnd5', 'dnd2024' then ::Item.dnd5.order(kind: :asc)
      else raise(ActiveRecord::RecordNotFound)
      end
    end
  end
end
