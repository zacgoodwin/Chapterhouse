# frozen_string_literal: true

class CustomResource < ApplicationRecord
  belongs_to :resourceable, polymorphic: true

  # Same algorithm as CharactersContext::Dnd5::Make{Short,Long}RestCommand's
  # inline refresh_resources case statement, generalized to any cadence key
  # (not just 'long'/'short'). Lives on the model instead of a third inline
  # copy so TLC's session cadence (ticket C8; no TLC rest command exists yet
  # to read it) and any future caller share one implementation. The existing
  # rest commands are left untouched -- not routed through this yet -- since
  # refactoring shipped dnd5/dnd2024 rest behavior is outside this ticket.
  def refreshed_value(current_value, cadence)
    change = resets[cadence.to_s]
    case change
    when -1 then reset_direction.zero? ? 0 : max_value
    when 0, nil then current_value
    else reset_direction.zero? ? [current_value - change.abs, 0].max : [current_value + change.abs, max_value].min
    end
  end
end
