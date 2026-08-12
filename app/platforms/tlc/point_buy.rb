# frozen_string_literal: true

module Tlc
  # PH 2024 p.38 point buy — the only ability-score method TLC character creation
  # offers (plan Phase A2: "level 3 default, point-buy only"). Costs are
  # cumulative from 8, and the 13->14 and 14->15 steps cost 2 rather than 1, so
  # callers must read the table instead of counting one point per step.
  #
  # Scores here are pre-species/background: the creation contract validates the
  # spread the player bought, before any boost is layered on.
  module PointBuy
    COST = { 8 => 0, 9 => 1, 10 => 2, 11 => 3, 12 => 4, 13 => 5, 14 => 7, 15 => 9 }.freeze
    BUDGET = 27
    MIN = COST.keys.min
    MAX = COST.keys.max

    # nil, never 0, when a score is off the table: an unpriceable spread has to
    # read as unaffordable rather than free.
    def self.spent(abilities)
      costs = abilities.values.map { |score| COST[score.to_i] }
      costs.include?(nil) ? nil : costs.sum
    end

    def self.affordable?(abilities)
      total = spent(abilities)

      !total.nil? && total <= BUDGET
    end
  end
end
