# frozen_string_literal: true

module TlcCharacter
  module Species
    class DwarfBuilder
      RESISTANCES = %w[poison].freeze

      def call(result:)
        result[:resistance] = result[:resistance].concat(RESISTANCES).uniq

        result
      end
    end
  end
end
