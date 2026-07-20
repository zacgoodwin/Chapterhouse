# frozen_string_literal: true

module TlcCharacter
  module Legacies
    class DrowBuilder
      def call(result:)
        result[:darkvision] = 120

        result
      end
    end
  end
end
