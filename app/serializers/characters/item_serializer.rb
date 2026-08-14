# frozen_string_literal: true

module Characters
  class ItemSerializer < ApplicationSerializer
    include ItemSerializing

    ATTRIBUTES = %i[
      id notes name kind data state item_id has_description states info bonuses modifiers item_modifiers custom
      charges charges_max
    ].freeze

    attributes(*ATTRIBUTES)

    def charges_max
      item.charges
    end
  end
end
