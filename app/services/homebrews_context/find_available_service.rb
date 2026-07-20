# frozen_string_literal: true

module HomebrewsContext
  class FindAvailableService
    def call(user_id:)
      {
        dnd2024: {
          races: dnd2024_races(user_id),
          subclasses: dnd2024_subclasses(user_id),
          backgrounds: titles(user_id, ::Dnd2024::Homebrews::Background)
        }
      }
    end

    private

    def titles(user_id, class_name)
      relation = class_name
      relation.where(user_id: user_id)
        .or(
          relation.where(id: available_books_data(user_id))
        )
        .each_with_object({}) { |item, acc| acc[item.id] = { name: item.title } }
    end

    def dnd2024_races(user_id)
      ::Dnd2024::Homebrews::Race.where(user_id: user_id)
        .or(
          ::Dnd2024::Homebrews::Race.where(id: available_books_data(user_id))
        )
        .each_with_object({}) do |item, acc|
          acc[item.id] = { name: item.title, sizes: item.info.size, legacies: [] }
        end
    end

    def dnd2024_subclasses(user_id)
      ::Dnd2024::Homebrews::Subclass.where(user_id: user_id)
        .or(
          ::Dnd2024::Homebrews::Subclass.where(id: available_books_data(user_id))
        )
        .each_with_object({}) do |item, acc|
          acc[item.info.class_id] ||= {}
          acc[item.info.class_id][item.id] = { name: item.title }
        end
    end

    def available_books_data(user_id)
      @available_books_data ||=
        ::Homebrew::Book::Item
          .where(itemable_type: 'Homebrew')
          .where(homebrew_book_id: ::User::Book.where(user_id: user_id).select(:homebrew_book_id))
          .pluck(:itemable_id)
    end
  end
end
