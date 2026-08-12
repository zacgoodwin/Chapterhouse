# frozen_string_literal: true

module Adminbook
  module Tlc
    class CharactersController < Adminbook::CharactersController
      private

      def character_type
        'Tlc::Character'
      end

      def provider
        'tlc'
      end
    end
  end
end
