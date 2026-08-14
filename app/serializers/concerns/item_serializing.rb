# frozen_string_literal: true

# Item payload shared by campaign and character items: both wrap an owned copy of
# a catalogue item, and read everything but the owner's overrides off that item.
module ItemSerializing
  extend ActiveSupport::Concern

  included do
    delegate :kind, :info, to: :item
    delegate :item, to: :object
  end

  def bonuses
    resp = Panko::ArraySerializer.new(
      object.item.bonuses,
      each_serializer: Characters::BonusSerializer
    )
    JSON.parse(resp.to_json)
  end

  def name
    object.name || translate(item.name)
  end

  def item_modifiers # rubocop: disable Rails/Delegate
    item.modifiers
  end

  def has_description # rubocop: disable Naming/PredicateMethod, Naming/PredicatePrefix
    translate(item.description).present?
  end

  def data
    item.data.attributes
  end

  def custom # rubocop: disable Naming/PredicateMethod
    object.name.present?
  end
end
