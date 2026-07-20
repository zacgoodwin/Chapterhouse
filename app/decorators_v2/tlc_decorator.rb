# frozen_string_literal: true

# The Leyfarer's Chronicle is a D&D 2024 variant, so its calc engine is
# identical to Dnd2024Decorator until a TLC house rule actually diverges. This
# empty subclass is the seam (plan A4/T2): real overrides land in C3, wired here
# without touching upstream. It is also the parity baseline's yardstick --
# spec/decorators_v2/tlc_decorator_spec.rb asserts this stays byte-identical to
# Dnd2024Decorator for every delta-free character, so the first unintended drift
# (upstream or ours) fails loudly instead of silently changing a stat.
class TlcDecorator < Dnd2024Decorator
end
