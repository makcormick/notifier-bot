# frozen_string_literal: true

module HistoryStore
  attr_accessor :next_sync_time, :trans_cache

  TRANS_BASE = 'https://api.ton.sh/getTransactions'
  POOL_WALLET = 'EQCUp88072pLUGNQCXXXDFJM3C5v9GXTjV7ou33Mj3r0Xv2W'
  MAX_SCAN_LEVEL = 40
  SYNC_PERIOD_TIME = 0.9

  def check_last_solutions
    new_searched_solutions = get_new_solutions_from(Setting.last_transaction['hash'])
    return if new_searched_solutions.blank?

    solution = new_searched_solutions.last
    Setting.last_transaction = solution
    new_searched_solutions
  end

  def resync
    destroy_all
    self.next_sync_time = nil
    deep_scan
    Setting.sync
  end

  def get_new_solutions_from(hash_of_last_transaction)
    transaction = Transaction.find_by(t_hash: hash_of_last_transaction)
    return [Transaction.first] if transaction.blank?

    Transaction.where('time > ?', transaction.time).reverse
  end

  def real_24h_profit
    solutions = last_24h_solutions
    solutions_count = solutions.count
    real_day_tons = (solutions_count * 100).to_f
    average_pool_hashrate = solutions.joins(:pool).average('pools.hashrate').to_i
    average_network_difficult = solutions.joins(:pool).average('pools.n_difficult').to_i
    profit = real_day_tons / to_gh(average_pool_hashrate)
    [average_pool_hashrate, average_network_difficult, real_day_tons, profit, solutions.last]
  end

  def last_24h_solutions
    Transaction.where('time > ?', Time.now - 24.hours)
  end

  def last_day_solutions_from(from_time = Time.now.utc, time_zone: nil)
    time = time_zone ? from_time.in_time_zone(time_zone) : from_time
    Transaction.where('time >= ? AND time <= ?', time.beginning_of_day, time)
  end

  def last_day_solutions_count_from(from_time = Time.now.utc, time_zone: nil)
    last_day_solutions_from(from_time, time_zone: time_zone).count
  end

  def deep_scan(next_page_url = nil, level = 1)
    @trans_cache = [] if level == 1

    current_time = Time.now

    if next_sync_time && next_sync_time > current_time
      log("Waiting for reloading history. Next allowed at #{format_time(next_sync_time, o_time: true)}\n"\
          "Next after: #{just_time(current_time - (next_sync_time - current_time))}")
      return
    end

    pool_info = Api::PoolInfo.current_pool_info
    if level > MAX_SCAN_LEVEL
      log "End of scan transaction. Level scan is #{MAX_SCAN_LEVEL}"
      @trans_cache.reverse.each { Transaction.from_data(_1, pool_info) }
      self.next_sync_time = current_time + SYNC_PERIOD_TIME.minutes
      return
    end

    trans = handle do
      url = next_page_url.presence ||
            URI(TRANS_BASE).tap { _1.query = URI.encode_www_form(address: POOL_WALLET) }.to_s
      data = request_json(url, log_text: '|transactions|')
      raise 'Transaction result is blank' if data['result'].blank?

      data
    end

    first_transaction = Transaction.first
    @trans_cache += trans['result'].select { _1['received']['nanoton'] == 10**11 }
    index_of_transaction = @trans_cache.index(@trans_cache.find { _1['hash'] == first_transaction&.t_hash })

    if index_of_transaction
      log("End scan #{first_transaction.t_hash}")
      self.next_sync_time = current_time + SYNC_PERIOD_TIME.minutes

      return if index_of_transaction.zero?

      @trans_cache[0...index_of_transaction].reverse.each { Transaction.from_data(_1, pool_info) }
      return
    end

    uri = URI(TRANS_BASE)
    uri.query = URI.encode_www_form(trans['previous_transaction'].merge(address: POOL_WALLET))
    next_url = uri.to_s

    deep_scan(next_url, level + 1)
  rescue StandardError => e
    log e.message
    log e.backtrace
    log 'Error in get transaction'
  end
end
