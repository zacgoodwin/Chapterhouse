# frozen_string_literal: true

module Frontend
  module Tlc
    module Characters
      # Rest semantics stay the inherited dnd2024 ones until C1 adds
      # rest_type=session; this class exists now so the tlc scope is enforced on
      # the endpoint from the start.
      class RestController < Frontend::Dnd2024::Characters::RestController
        private

        def find_character
          @character = authorized_scope(::Character.all).tlc.find(params.expect(:character_id))
        end
      end
    end
  end
end
