# frozen_string_literal: true

module HomebrewsV2
  module Tlc
    class FeatsController < HomebrewsV2::FeatsController
      private

      def serializer = ::HomebrewsV2::Tlc::FeatSerializer
      def class_name = ::Tlc::Feat

      # Standard homebrew visibility scoping: a user sees their own rows plus any
      # publicly shared ones (book union via includes). Same rule as the dnd2024
      # feats browse; STI (::Tlc::Feat) already scopes to type 'Tlc::Feat'.
      def find_feats
        @feats =
          class_name.where(user_id: current_user.id).or(class_name.where(public: true))
            .where(origin: 'feat')
            .includes(:homebrew_books)
      end

      def order_options
        { key: %w[title] }
      end
    end
  end
end
