# frozen_string_literal: true

module Tlc
  # STI subclass so `type: 'Tlc::Spell'` rows resolve to a real class. The spells
  # table is dnd5-only upstream; TLC spells are normally Tlc::Feat records with
  # origin 6, so this exists mainly for the tlc_content content union.
  class Spell < Spell
    include Tlc::ContentFlags

    tlc_content meta: :data, name: :name
  end
end
