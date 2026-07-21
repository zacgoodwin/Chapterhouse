# frozen_string_literal: true

module CharactersContext
  module Tlc
    # See MakeShortRestCommand: mechanics inherited, contract restated because
    # Tlc::Character is not a Dnd2024::Character.
    class MakeLongRestCommand < CharactersContext::Dnd2024::MakeLongRestCommand
      use_contract do
        params do
          required(:character).filled(type?: ::Tlc::Character)
        end
      end
    end
  end
end
