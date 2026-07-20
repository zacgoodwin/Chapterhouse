# frozen_string_literal: true

module TlcCharacter
  module Species
    class AasimarBuilder
      RESISTANCES = %w[necrotic radiant].freeze

      def call(result:)
        result[:resistance] = result[:resistance].concat(RESISTANCES).uniq

        result
      end
    end
  end
end
