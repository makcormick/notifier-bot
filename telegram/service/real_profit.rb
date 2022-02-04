# frozen_string_literal: true

module Service
  class RealProfit
    attr_accessor :store

    def initialize; end

    def perform
      return store if store

      solutions = last_24h_solutions
      solutions_count = solutions.count
      real_day_tons = (solutions_count * 100).to_f
      average_pool_hashrate = solutions.joins(:pool).average('pools.hashrate').to_i
      average_network_difficult = solutions.joins(:pool).average('pools.n_difficult').to_i
      profit = real_day_tons / to_gh(average_pool_hashrate)
      self.store = [average_pool_hashrate, average_network_difficult, real_day_tons, profit, solutions.last]
    end

    private

    def last_24h_solutions
      Transaction.where('time > ?', Time.now - 24.hours)
    end
  end
end
