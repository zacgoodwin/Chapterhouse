# frozen_string_literal: true

module Campaigns
  class ItemSerializer < ApplicationSerializer
    include ItemSerializing

    ATTRIBUTES = %i[
      id notes name kind data item_id has_description states info bonuses modifiers item_modifiers custom
    ].freeze

    attributes(*ATTRIBUTES)
  end
end
