# frozen_string_literal: true

class Formula
  # Dentaku::Calculator#evaluate (non-bang, used below) already rescues
  # Dentaku::Error and its subclasses internally -- ParseError and
  # UnboundVariableError included -- and returns nil; verified against
  # dentaku 3.5.7's Calculator#evaluate source and by fuzzing ~25 malformed
  # formulas (bad syntax, unbound vars, wrong arg counts, a 0-sided d(),
  # divide-by-zero) through this method, none of which raised. The explicit
  # rescue below is redundant today but makes the "never raises for a bad
  # formula" contract ours instead of an implicit dependency on dentaku's
  # internals (T3, plan Observability) -- if a future dentaku upgrade changes
  # evaluate's behavior, this still holds, and spec/lib/formula_spec.rb pins
  # it either way.
  def call(formula:, variables: {})
    calculator.evaluate(formula, **variables)
  rescue Dentaku::ParseError, Dentaku::UnboundVariableError
    nil
  end

  private

  def calculator
    @calculator ||= begin
      result = Dentaku::Calculator.new
      result.add_function(:d, :numeric, ->(dice_value) { rand(1..dice_value.to_i.abs) })
      result
    end
  end
end
