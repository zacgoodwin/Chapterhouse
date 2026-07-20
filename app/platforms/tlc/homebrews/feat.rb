# frozen_string_literal: true

module Tlc
  # Homebrew authoring record for a standalone TLC feat (the 5 origin + 8 general
  # feats, players-guide-digest.md §6). `< ::Homebrew` per the plan: the container
  # groups the backing feat row and any embedded "choose one of N" sub-choice rows
  # (e.g. Draconic Ancestry's Gifts) under one authoring/browse unit, while the
  # selectable content itself stays a Tlc::Feat row (origin 'feat') so a character
  # references it exactly like a seeded feat. Feat-level authoring metadata
  # (repeatable / prerequisite / unlock gate) lives in info; per-use limits and
  # mechanics live on the backing Tlc::Feat, never in an eval field.
  module Homebrews
    class FeatData
      include StoreModel::Model

      attribute :repeatable, :boolean, default: false
      attribute :prerequisite, :string
      attribute :unlock, :string # none / chapter_N / reputation / special / little_leyfarers
    end

    class Feat < ::Homebrew
      attribute :info, Tlc::Homebrews::FeatData.to_type

      def to_homebrew_json(with_id: true)
        [
          {
            id: with_id ? id : nil,
            title: title,
            description: description,
            public: attributes['public'],
            repeatable: info.repeatable,
            prerequisite: info.prerequisite,
            unlock: info.unlock,
            features: ::Tlc::Feat.where(origin: 'feat', origin_value: id).map { |item|
              item.to_homebrew_json(with_id: with_id)
            }
          }.compact
        ]
      end
    end
  end
end
