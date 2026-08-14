# frozen_string_literal: true

module CharactersContext
  # `money` (total copper) and `coins` (gold/silver/copper) are two views of the
  # same purse, and a client sends whichever one its screen edits. Shared by the
  # provider update commands so both views persist in step.
  module CoinsSyncing
    private

    def sync_coins_and_money(input)
      if input.key?(:money)
        gold, modulus = input[:money].divmod(100)
        silver, copper = modulus.divmod(10)
        input[:coins] = { copper: copper, silver: silver, gold: gold }
      elsif input.key?(:coins)
        input[:money] = (input.dig(:coins, :gold) * 100) + (input.dig(:coins, :silver) * 10) + input.dig(:coins, :copper)
      end
    end
  end
end
