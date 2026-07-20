# frozen_string_literal: true

class CustomResource < ApplicationRecord
  belongs_to :resourceable, polymorphic: true

  # Same algorithm as CharactersContext::Dnd5::Make{Short,Long}RestCommand's
  # inline refresh_resources case statement (dnd2024 inherits both, so this
  # covers dnd5 and dnd2024 too), generalized to any cadence key (not just
  # 'long'/'short'). Lives on the model instead of a third inline copy so
  # TLC's session cadence (ticket C8; no TLC rest command exists yet to read
  # it) and any future caller share one implementation. A resets hash missing
  # the queried cadence key (change is nil) is a no-op, matching the shipped
  # rest commands' own `when 0, nil` branch -- both were audited to agree
  # after a QA pass found the shipped commands missing that branch and added
  # it there (see spec/models/custom_resource_spec.rb's partial-resets case).
  def refreshed_value(current_value, cadence)
    change = resets[cadence.to_s]
    case change
    when -1 then reset_direction.zero? ? 0 : max_value
    when 0, nil then current_value
    else reset_direction.zero? ? [current_value - change.abs, 0].max : [current_value + change.abs, max_value].min
    end
  end
end
