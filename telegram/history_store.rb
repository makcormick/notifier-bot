# frozen_string_literal: true

module HistoryStore
  attr_accessor :store, :next_sync_time, :trans_cache

  TRANS_BASE = 'https://api.ton.sh/getTransactions'
  POOL_WALLET = 'EQCUp88072pLUGNQCXXXDFJM3C5v9GXTjV7ou33Mj3r0Xv2W'
  MAX_SCAN_LEVEL = 40
  SYNC_PERIOD_TIME = 0.9
  MAX_STORE_SIZE = 600

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
    self.store = []
    deep_scan
    Setting.sync
  end

  def get_new_solutions_from(hash_of_last_transaction)
    scan_result = deep_scan

    return if scan_result.blank?

    index_of_last_notified_transaction = scan_result.index { _1.t_hash == hash_of_last_transaction }
    return [scan_result.first] if index_of_last_notified_transaction.blank?

    return if index_of_last_notified_transaction.zero?

    scan_result[0...index_of_last_notified_transaction].reverse
  end

  def real_24h_profit
    solutions = last_24h_solutions
    real_day_tons = (solutions.size * 100).to_f
    average_pool_hashrate = solutions.map { _1.pool.hashrate.to_i }.sum / solutions.count
    average_network_difficult = solutions.map { _1.pool.n_difficult.to_i }.sum / solutions.count
    profit = real_day_tons / to_gh(average_pool_hashrate)
    [average_pool_hashrate, average_network_difficult, real_day_tons, profit, solutions]
  end

  def last_24h_solutions
    time = Time.now - 24.hours
    @store.select { _1.time >= time }
  end

  def last_day_solutions_from(from_time = Time.now.utc, time_zone: nil)
    time = time_zone ? from_time.in_time_zone(time_zone) : from_time
    @store.select { _1.time >= time.beginning_of_day && _1.time <= time }
  end

  def last_day_solutions_count_from(from_time = Time.now.utc, time_zone: nil)
    last_day_solutions_from(from_time, time_zone: time_zone).size
  end

  def deep_scan(next_page_url = nil, level = 1)
    if level == 1
      @store = Transaction.first(MAX_STORE_SIZE) if @store.blank?
      @store = @store[0...MAX_STORE_SIZE] if @store.size > MAX_STORE_SIZE
      @trans_cache = []
    end

    current_time = Time.now

    if next_sync_time && next_sync_time > current_time
      log("Waiting for reloading history. Next allowed at #{format_time(next_sync_time)}\n"\
          "Next after: #{just_time(current_time - (next_sync_time - current_time))}")
      return @store
    end

    pool_info = Api::PoolInfo.fetch
    if level > MAX_SCAN_LEVEL
      log "End of scan transaction. Level scan is #{MAX_SCAN_LEVEL}"
      @trans_cache.reverse.each { Transaction.from_data(_1, pool_info) }
      @store = Transaction.first(MAX_STORE_SIZE)
      self.next_sync_time = current_time + SYNC_PERIOD_TIME.minutes
      return @store
    end

    trans = handle do
      url = next_page_url.presence ||
            URI(TRANS_BASE).tap { _1.query = URI.encode_www_form(address: POOL_WALLET) }.to_s
      data = request_json(url, log_text: '|transactions|')
      raise 'Transaction result is blank' if data['result'].blank?

      data
    end

    @trans_cache += trans['result'].select { _1['received']['nanoton'] == 10**11 }
    index_of_transaction = @trans_cache.index(@trans_cache.find { _1['hash'] == @store.first&.t_hash })

    if index_of_transaction
      log("End scan #{@store.first.t_hash}")
      self.next_sync_time = current_time + SYNC_PERIOD_TIME.minutes

      return @store if index_of_transaction.zero?

      @trans_cache[0...index_of_transaction].reverse.each { Transaction.from_data(_1, pool_info) }
      return @store = Transaction.first(MAX_STORE_SIZE)
    end

    uri = URI(TRANS_BASE)
    uri.query = URI.encode_www_form(trans['previous_transaction'].merge(address: POOL_WALLET))
    next_url = uri.to_s

    deep_scan(next_url, level + 1)
  rescue StandardError => e
    log e.message
    log e.backtrace
    log 'Error in get transaction'
    @store
  end
end
