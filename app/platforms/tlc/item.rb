# frozen_string_literal: true

module Tlc
  # STI subclass so `type: 'Tlc::Item'` rows resolve to a real class (unlike the
  # dnd2024 items, whose `Dnd2024::Item` is only a serializer namespace). Data
  # stays as raw JSONB, matching the dnd2024 variant it mirrors.
  class Item < Item
  end
end
