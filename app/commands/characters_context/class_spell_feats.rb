# frozen_string_literal: true

module CharactersContext
  # dnd2024-style spell lists: a spell is a Feat row with origin `class_spell`
  # (6), attached to the character and tagged with the class that prepared it, so
  # dropping a class can drop exactly the spells it brought. Including commands
  # supply the content scope and the homebrew feat types their provider owns.
  module ClassSpellFeats
    private

    def spell_feats_scope = raise(NotImplementedError)
    def homebrew_feat_types = raise(NotImplementedError)

    def refresh_class_spells(input)
      character = input[:character]
      input[:added_classes].each do |added_class|
        learn_class_spells(character: character, class_name: added_class, user: character.user)
      end
      input[:removed_classes].each { |removed_class| forget_class_spells(character: character, class_name: removed_class) }
    end

    def learn_class_spells(character:, class_name:, user:)
      return if ::Dnd2024::Character::CLASSES_KNOW_SPELLS_LIST.exclude?(class_name)

      relation = spell_feats_scope.where(origin: 6).where('origin_values && ?', "{#{class_name}}")
      spells =
        relation.where(user_id: [nil, user.id]).or(relation.where(id: homebrew_feat_ids(user)))
        .map do |feat|
          {
            character_id: character.id,
            feat_id: feat.id,
            ready_to_use: false,
            value: { prepared_by: class_name }
          }
        end
      ::Character::Feat.upsert_all(spells) if spells.any?
    end

    def forget_class_spells(character:, class_name:)
      character.feats.where("value -> 'prepared_by' ? :prepared_by", prepared_by: class_name).delete_all
    end

    def homebrew_feat_ids(user)
      ::Homebrew::Book::Item
        .where(homebrew_book_id: ::User::Book.where(user_id: user).select(:homebrew_book_id))
        .where(itemable_type: homebrew_feat_types)
        .pluck(:itemable_id)
    end
  end
end
