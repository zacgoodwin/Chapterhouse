# frozen_string_literal: true

module Frontend
  module Tlc
    module Characters
      # Rest MECHANICS stay the inherited dnd2024 ones until C1 adds
      # rest_type=session, but the commands must be the TLC-contract subclasses:
      # the dnd2024 ones validate `type?: ::Dnd2024::Character` and 422 on every
      # Tlc::Character. This class also pins the tlc scope on the endpoint.
      class RestController < Frontend::Dnd2024::Characters::RestController
        include Deps[
          make_short_rest: 'commands.characters_context.tlc.make_short_rest',
          make_long_rest: 'commands.characters_context.tlc.make_long_rest'
        ]

        private

        def find_character
          @character = authorized_scope(::Character.all).tlc.find(params.expect(:character_id))
        end
      end
    end
  end
end
