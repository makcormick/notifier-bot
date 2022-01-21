# frozen_string_literal: true

class NotifyApi
  @cache = {}

  class << self
    attr_accessor :cache

    def last_giver_info(transaction = Setting.last_transaction, user: nil, time_zone: 0)
      t_time = transaction.is_a?(Transaction) ? transaction.time : transaction['timestamp']
      giver = transaction.is_a?(Transaction) ? transaction.giver : transaction['giver']

      tz = user&.time_zone || time_zone
      timestamp = t_time
      found_time = timestamp.in_time_zone(tz)
      found_time_formatted = format_time(timestamp, time_zone: tz)
      last_day_solutions_count = Transaction.last_day_solutions_count_from(found_time)

      average_pool_hashrate, average_network_difficult, real_day_tons, profit, solutions = Transaction.real_24h_profit
      real_day_tons_usd = real_day_tons * ton_price
      profit_usd = profit * ton_price
      expected_solutions_in_day = 24.to_f * 3600 / (to_gh(average_network_difficult) / to_gh(average_pool_hashrate))
      start_time = solutions.last.time
      expected_day_tons = expected_solutions_in_day * 100

      expected_solutions_in_day_info = expected_solutions_in_day.round(2)
      solution_goal_info = (last_day_solutions_count / expected_solutions_in_day * 100).round(2)
      start_time_info = b(format_time(start_time, time_zone: tz))
      start_time_words_info = b(start_time.ago_in_words)
      average_network_difficult_info = b(to_ph(average_network_difficult).round(2))
      average_network_difficult_th_info = b(to_th(average_network_difficult).round(2))
      average_pool_hashrate_info = b(to_th(average_pool_hashrate).round(2))
      real_day_tons_info = b(real_day_tons)
      real_day_tons_usd_info = b(real_day_tons_usd.round(2))
      expected_day_tons_info = b((expected_solutions_in_day * 100).round(2))
      luck_state_info = b((user || I18n).t(real_day_tons > expected_day_tons ? 'lucky_day' : 'unlucky_day'))
      profit_info = b(profit.round(4))
      profit_usd_info = b(profit_usd.round(2))
      ton_price_info = b("#{ton_price.round(2)}$")

      (user || I18n).t('last_solution_info',
                       found_time_formatted: found_time_formatted,
                       pool_wallet: HistoryStore::POOL_WALLET,
                       giver_wallet: giver,
                       last_day_solutions_count: last_day_solutions_count,
                       expected_solutions_in_day_info: expected_solutions_in_day_info,
                       solution_goal_info: solution_goal_info,
                       start_time_info: start_time_info,
                       start_time_words_info: start_time_words_info,
                       average_network_difficult_info: average_network_difficult_info,
                       average_network_difficult_th_info: average_network_difficult_th_info,
                       average_pool_hashrate_info: average_pool_hashrate_info,
                       real_day_tons_info: real_day_tons_info,
                       real_day_tons_usd_info: real_day_tons_usd_info,
                       expected_day_tons_info: expected_day_tons_info,
                       luck_state_info: luck_state_info,
                       profit_info: profit_info,
                       profit_usd_info: profit_usd_info,
                       ton_price_info: ton_price_info)
    end

    def pool_data(user)
      if cache[user.tg_id] && cache[user.tg_id][:next_time] > Time.now && user.tg_id != '593856889'.to_i
        log "#{user.debug_user_info} pool_data request from cache"

        if cache.size > 100
          log "Clearing cache #{format_time}"
          self.cache = {}
        end

        return 'Circulation period 30 seconds, wait please '\
               "#{b((cache[user.tg_id][:next_time] - Time.now).round(2))} seconds"
      end

      log "#{user.debug_user_info} request pool_data"

      data_net = Api::PoolInfo.fetch
      pool_hashrate = data_net.hashrate.to_f
      network_difficulty = data_net.n_difficult.to_f
      network_difficult = to_ph(network_difficulty)
      last_challenge_solved = data_net.last_solved_time
      hours_for_solution = (network_difficulty / pool_hashrate / 3600)
      solution_in_day = (24 / hours_for_solution).round(1)
      daily_reward = solution_in_day * 100
      total_reward = daily_reward * ton_price
      time_passed = ((Time.now.utc - data_net.last_solved_time) / 3600)
      current_luck = (time_passed / hours_for_solution * 100).round(3)
      profit_gh = daily_reward / to_gh(pool_hashrate)
      profit_gh_usd = ton_price * profit_gh

      pool_hashrate_info = b(to_th(pool_hashrate))
      network_difficult_info = b(network_difficult)
      last_challenge_solved_words_info = b(last_challenge_solved.ago_in_words)
      last_challenge_solved_info = b(user.f_time(last_challenge_solved))
      hours_for_solution_words_info = b(just_time(Time.now - hours_for_solution.hours))
      solution_in_day_info = b(solution_in_day)
      daily_reward_info = b(daily_reward.to_i)
      total_reward_info = b("#{total_reward.round(2)}$")
      current_luck_info = b("#{current_luck}%")
      current_luck_status_info = (user || I18n).t(current_luck < 100 ? 'lucky' : 'unlucky')
      profit_gh_info = b(profit_gh.round(4))
      profit_gh_usd_info = b("#{profit_gh_usd.round(4)}$")
      ton_price_info = b("#{ton_price.round(3)}$")

      cache[user.tg_id] = { next_time: Time.now + 30 }

      (user || I18n).t(
        'pool_data_info',
        pool_hashrate_info: pool_hashrate_info,
        network_difficult_info: network_difficult_info,
        last_challenge_solved_words_info: last_challenge_solved_words_info,
        last_challenge_solved_info: last_challenge_solved_info,
        hours_for_solution_words_info: hours_for_solution_words_info,
        solution_in_day_info: solution_in_day_info,
        daily_reward_info: daily_reward_info,
        total_reward_info: total_reward_info,
        current_luck_info: current_luck_info,
        current_luck_status_info: current_luck_status_info,
        profit_gh_info: profit_gh_info,
        profit_gh_usd_info: profit_gh_usd_info,
        ton_price_info: ton_price_info
      )
    end

    private

    def ton_price
      Api::Price::Gecko.price
    end
  end
end
