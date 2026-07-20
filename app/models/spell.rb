# frozen_string_literal: true

class Spell < ApplicationRecord
  include Itemable

  scope :dnd5, -> { where(type: 'Dnd5::Spell') }
  scope :tlc, -> { where(type: 'Tlc::Spell') } # STRICT: own type only
  scope :tlc_content, -> { where(type: %w[Dnd2024::Spell Tlc::Spell]) } # P4 content union

  has_many :character_spells, class_name: '::Character::Spell', dependent: :destroy
end
