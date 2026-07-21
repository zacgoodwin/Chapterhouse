# frozen_string_literal: true

module Tlc
  # Everything Dnd2024::CharacterSerializer exposes (Panko duplicates the parent
  # descriptor on inherit) plus the five TLC data fields, with `provider`
  # flipped. Frontend::CharactersController#show resolves this class from
  # `character.type` ("Tlc::Character" -> "Tlc::CharacterSerializer"), so no
  # per-provider case statement is needed there.
  class CharacterSerializer < Dnd2024::CharacterSerializer
    # Declared as attributes then delegated: Panko's `method_added` hook moves
    # each one into method_fields, which is how the parent exposes its
    # decorator-backed fields too.
    attributes :leyfarer_rank, :leyfarer_focus, :selected_traits, :mixed_species, :dismissed_warnings

    delegate :leyfarer_rank, :leyfarer_focus, :selected_traits, :mixed_species, :dismissed_warnings, to: :data

    def provider
      'tlc'
    end
  end
end
