# frozen_string_literal: true

# A0-2 modifier-expressiveness spot check (docs/leyfarers-implementation-plan.md,
# Phase A0 encoding table). Evaluates every formula the table claims "fits"
# through the REAL app/lib/formula.rb (Dentaku 3.5.7 + the d() dice function the
# app registers at formula.rb:13), and demonstrates the two mechanics that
# provably CANNOT be modifiers. Run from the repo root:
#
#   ruby docs/reference/a0_modifier_formula_check.rb
#
# Not a gate test (it uses rand via d()) — a reproducible verdict artifact.

require 'bundler/setup'
require 'dentaku'
ROOT = File.expand_path('../..', __dir__)
require File.join(ROOT, 'app', 'lib', 'formula')

failures = []

def check(failures, label, formula, vars, expected)
  got = Formula.new.call(formula: formula, variables: vars)
  ok = got == expected
  failures << label unless ok
  status = ok ? 'PASS' : 'FAIL'
  puts "  [#{status}] #{label.ljust(42)} #{formula.inspect.ljust(42)} => #{got.inspect} (want #{expected.inspect})"
end

puts 'FITS (evaluated via app/lib/formula.rb):'
# Row 1 — choose-one AC: set armor_class = 13 + Dex/Con mod (max-of-set = best choice)
check(failures, 'AC 13+Dex (set armor_class)', '13 + dex', { dex: 2 }, 15)
check(failures, 'AC 13+Con Turtlefolk (set)', '13 + con', { con: 3 }, 16)
# Row 4 — Snail's Pace: add speed -10
check(failures, "Snail's Pace speed (add speed)", '-10', {}, -10)
# Row 7 (speed half) — Vial of Sand carried: add speed -10 (item modifier)
check(failures, 'Vial carried speed (add speed)', '-10', {}, -10)
# Proves Dentaku IF is available -> an unarmored-only AC guard is expressible
ac_guard = 'if(no_body_armor, 13 + con, armor_class)'
check(failures, 'Unarmored AC guard true (IF)', ac_guard, { no_body_armor: true, con: 3, armor_class: 12 }, 16)
check(failures, 'Armored AC picks base (IF)', ac_guard, { no_body_armor: false, con: 3, armor_class: 18 }, 18)
# Rows 8/9 — the "PB per LR" USE-LIMIT half is a plain formula
check(failures, 'PB-per-LR use limit', 'proficiency_bonus', { proficiency_bonus: 3 }, 3)

puts
puts 'NEEDS-EXTENSION evidence (why these are NOT modifiers):'

# Rows 6 & 7 — a stored per-LR die cannot be a modifier: a modifier re-evaluates
# on every decorate() call and would reroll.
rolls = Array.new(60) { Formula.new.call(formula: 'd(20)', variables: {}) }
distinct = rolls.uniq.size
reroll_ok = rolls.all? { |r| r.between?(1, 20) } && distinct > 1
failures << 'd() reroll demo' unless reroll_ok
reroll_status = reroll_ok ? 'PASS' : 'FAIL'
reroll_label = 'd(20) rerolls every eval'.ljust(38)
puts "  [#{reroll_status}] #{reroll_label} 60 rolls -> #{distinct} distinct in 1..20 (a stored roll can't be a modifier)"

# Row 8 — leyfarer_rank is NOT in formula_variables today, so a formula
# referencing it resolves to nil (Formula uses the non-bang evaluate).
rank_result = Formula.new.call(formula: 'leyfarer_rank', variables: {})
rank_ok = rank_result.nil?
failures << 'leyfarer_rank unbound' unless rank_ok
rank_status = rank_ok ? 'PASS' : 'FAIL'
rank_label = 'leyfarer_rank in a formula'.ljust(38)
puts "  [#{rank_status}] #{rank_label} unbound => #{rank_result.inspect} (rank is not a formula variable yet)"

puts
if failures.empty?
  puts 'ALL CHECKS PASSED'
  exit 0
else
  puts "FAILURES: #{failures.join(', ')}"
  exit 1
end
