# frozen_string_literal: true

module Frontend
  module Tlc
    # TLC is a D&D 2024 variant: identical actions, different commands,
    # serializer and authorization scope. `import` is inherited but deliberately
    # unrouted -- there is no ImportContext::Tlc.
    class CharactersController < Frontend::Dnd2024::CharactersController
      include Deps[
        character_create: 'commands.characters_context.tlc.create',
        character_update: 'commands.characters_context.tlc.update'
      ]

      private

      def render_character(result, fields, status)
        serialize_resource(result, ::Tlc::CharacterSerializer, :character, fields, status)
      end

      # STRICT provider scope (Character.tlc): a dnd2024 character must 404 on a
      # tlc endpoint, and another user's character must 404 via action_policy.
      def character
        authorized_scope(::Character.all).tlc.find(params.expect(:id))
      end
    end
  end
end
