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
    attributes :leyfarer_rank, :leyfarer_focus, :selected_traits, :mixed_species, :dismissed_warnings, :warnings

    delegate :leyfarer_rank, :leyfarer_focus, :selected_traits, :mixed_species, :dismissed_warnings, to: :data

    def provider
      'tlc'
    end

    # Active warnings only; `dismissed_warnings` ships alongside so the settings
    # restore surface (D5) can list what was hidden. Filtering here rather than
    # inside Tlc::Warnings keeps the engine a pure rule check -- the dismissal
    # set is presentation state, and D5 needs the unfiltered slugs too.
    def warnings
      ::Tlc::Warnings.call(decorator: decorator).reject { |warning| dismissed_warnings.include?(warning[:slug]) }
    end
  end
end
