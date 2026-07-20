# frozen_string_literal: true

module Tlc
  # Homebrew authoring record for a TLC subclass, mirroring
  # Dnd2024::Homebrews::Subclass. `info.resources` carries C8-shaped resource
  # definitions (db/data/tlc/resources.json schema: slug/name/description/
  # min_class_level/max_formula/max_value/reset_direction/resets) so a homebrew
  # subclass's pools instantiate through the exact same
  # CharactersContext::Tlc::RefreshResources machinery the 12 seeded subclasses
  # use — see that service's homebrew-source union. Stored as a plain jsonb array
  # (codebase convention for homebrew info blobs, e.g. RaceData#vision), read by
  # RefreshResources via string keys. Features (level-gated) live on Tlc::Feat
  # rows (origin 'subclass').
  module Homebrews
    class SubclassData
      include StoreModel::Model

      attribute :class_id, :string
      attribute :resources, array: true, default: []
    end

    class Subclass < ::Homebrew
      attribute :info, Tlc::Homebrews::SubclassData.to_type

      def to_homebrew_json(with_id: true)
        [
          {
            id: with_id ? id : nil,
            title: title,
            description: description,
            public: attributes['public'],
            class_id: info.class_id,
            resources: info.resources,
            features: ::Tlc::Feat.where(origin: 'subclass', origin_value: id).map { |item|
              item.to_homebrew_json(with_id: with_id)
            }
          }.compact
        ]
      end
    end
  end
end
