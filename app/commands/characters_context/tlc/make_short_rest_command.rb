# frozen_string_literal: true

module CharactersContext
  module Tlc
    # Rest MECHANICS are dnd2024's until C1 adds rest_type=session; only the
    # contract differs. Tlc::Character is a sibling of Dnd2024::Character
    # (both inherit ::Character), so the parent's `type?: ::Dnd2024::Character`
    # rejects every TLC character -- the contract has to be restated, it cannot
    # be inherited.
    class MakeShortRestCommand < CharactersContext::Dnd2024::MakeShortRestCommand
      use_contract do
        params do
          required(:character).filled(type?: ::Tlc::Character)
          optional(:options).hash do
            required(:d6).filled(:integer, gteq?: 0)
            required(:d8).filled(:integer, gteq?: 0)
            required(:d10).filled(:integer, gteq?: 0)
            required(:d12).filled(:integer, gteq?: 0)
          end
          optional(:make_rolls).filled(:bool)
        end
      end
    end
  end
end
