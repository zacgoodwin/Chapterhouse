# frozen_string_literal: true

class Feat < ApplicationRecord
  include Itemable
  include Homebrewable
  include Upvoteable

  scope :dnd5, -> { where(type: 'Dnd5::Feat') }
  scope :dnd2024, -> { where(type: 'Dnd2024::Feat') }
  scope :tlc, -> { where(type: 'Tlc::Feat') } # STRICT: own type only
  scope :tlc_content, -> { where(type: %w[Dnd2024::Feat Tlc::Feat]) } # P4 content union

  belongs_to :user, optional: true

  has_many :character_feats, class_name: 'Character::Feat', dependent: :destroy
  has_many :bonuses, class_name: '::Character::Bonus', as: :bonusable, dependent: :destroy

  def to_homebrew_json(with_id: true)
    attributes
      .slice('title', 'description', 'kind', 'price', 'limit_refresh', 'modifiers', 'exclude', 'continious', 'tokens')
      .merge({
        id: with_id ? id : nil,
        limit: description_eval_variables['limit'],
        subclass_mastery: conditions['subclass_mastery'],
        level: conditions['level'],
        type: info['type'],
        recall: info['recall'],
        hope_dice: info['hope_dice'],
        fear_dice: info['fear_dice']
      }).compact_blank
  end
end
