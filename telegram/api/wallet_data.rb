# frozen_string_literal: true

module Api
  class WalletData
    TO_ADMIN_MESSAGE = 'Error in get data for wallet, try to set correct wallet'
    CACHE_TIMEOUT_PERIOD = 30 # in seconds

    @cache = {}

    # EQAej9CEm_IgTpOFKkqwZSSQuUthWn-h2dtU1dx4BKlCaFJp

    class << self
      attr_accessor :cache

      def perform(wallet)
        if cache[wallet] && cache[wallet][:next_time] > Time.now
          log "From cache for #{wallet}. "\
              "Next possible after #{b((cache[wallet][:next_time] - Time.now).round(2))} seconds"

          cached_data = cache[wallet][:data]

          if cache.size > 100
            log 'Clearing WalletData cache'
            self.cache = {}
          end

          return cached_data
        end

        log "Wallet data for #{wallet}"
        data_net = Api::PoolInfo.current_pool_info
        text = []
        pool_hashrate = data_net.hashrate.to_f
        network_difficulty = data_net.n_difficult.to_f
        current_pool_hashrate = to_th(pool_hashrate)
        network_difficult = to_ph(network_difficulty)
        text << 'For wallet'
        text << b(wallet)
        text << "Current pool hashrate: #{b(current_pool_hashrate)} Th/s"
        text << "Current network difficult: #{b(network_difficult)} PH"
        time_passed = ((Time.now.utc - data_net.last_solved_time) / 3600)
        text << "Last Block: #{b(format_time(data_net.last_solved_time, time_zone: 3))} UTC "\
                "(#{b(data_net.last_solved_time.ago_in_words)})"

        hours_for_solution = network_difficulty / pool_hashrate / 3600 # hours for solution
        solution_in_day = (24 / hours_for_solution)

        text << "\n"
        text << "Expected time for solution: #{b(just_time(Time.now - hours_for_solution.hours))}"
        text << "Expected solutions in day: #{b(solution_in_day.round(1))}"
        current_luck = (time_passed / hours_for_solution * 100).round(4)
        text << "Current solution luck: #{b(current_luck)}%"
        text << "\n"

        url = "https://toncoinpool.io/api/v1/public/miners/#{wallet}"
        data_min = request_json(url, log_text: '|wallet|')
        partition = data_min['part'].to_f / 100
        max_for_name = data_min['rigs'].map { _1['name'] }.max_by(&:size)&.size || 7
        text << 'Rig information'
        total_hashrate = 0

        data_min['rigs'].each do |rig|
          accepted_shares = rig['buckets'].map(&:first)
          staled_shares = rig['buckets'].map(&:second)
          staled_duplicated = rig['buckets'].map(&:third)

          rig_hashrate = Service::PoolHashrate.new(accepted_shares).perform
          total_hashrate += rig_hashrate

          shares = { accepted: accepted_shares.sum, staled: staled_shares.sum, duplicated: staled_duplicated.sum }
                   .map { |k, v| "#{just(k, 6)}: #{just(b(v), 7)}" }.join(' | ')
          worker = rig['name'].ljust(max_for_name, ' ') + " ---> #{b(to_gh(rig_hashrate).round(2))} Gh/s"
          text << worker
          text << shares
        end

        text << "\n"
        text << "Total miner hashrate: #{b(to_gh(total_hashrate).round(2))} GH/s"

        # effective_hashrate = to_gh(pool_hashrate * partition)
        # text << "Miner effective hashrate on pool: #{b(effective_hashrate.round(2))} GH/s"

        balance = data_min['balance'].to_f / 10**9
        expected_prev_balance = balance - (partition * 1)
        text << "Miner balance: #{b(balance)} tons (previous #{b(expected_prev_balance.round(5))})"
        text << "Miner's PPLNS Shares partition: #{b(data_min['part'])}%"
        text << "Expected partition: #{b((total_hashrate / pool_hashrate * 100).round(4))}%"

        expected_miner_profit = expected_miner_profit(solution_in_day, partition).round(4)
        expected_profit_for_gh = expected_profit_for_gh(solution_in_day, pool_hashrate).round(4)
        expected_miner_profit_usd = (expected_miner_profit * ton_price).round(4)
        expected_profit_for_gh_usd = (expected_profit_for_gh * ton_price).round(4)

        text << 'Expected on current pool partition:'
        text << "---> Miner profit in day: #{b(expected_miner_profit)} tons (#{b(expected_miner_profit_usd)}$)"
        text << 'Expected on current pool hashrate:'
        text << "---> Profitability per 1.00 GH/s: #{b(expected_profit_for_gh)} tons "\
                "(#{b(expected_profit_for_gh_usd)}$)"
        text << "Ton price: #{b("#{ton_price.round(2)}$")}"

        data = text.join("\n")
        cache[wallet] = { next_time: Time.now + CACHE_TIMEOUT_PERIOD, data: data }
        data
      rescue StandardError => e
        log e.message
        log e.backtrace
        log 'Error in WalletData perform'
        cache[wallet] ? cache[wallet][:data] : TO_ADMIN_MESSAGE
      end

      private

      def ton_price
        Api::Price::Gecko.current_price
      end

      def expected_miner_profit(solution_in_day, pool_partition)
        solution_in_day * 100 * pool_partition
      end

      def expected_profit_for_gh(solution_in_day, pool_hashrate)
        solution_in_day * 100 / to_gh(pool_hashrate)
      end
    end
  end
end
