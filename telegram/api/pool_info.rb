# frozen_string_literal: true

module Api
  class PoolInfo
    POOL_INFO_URL = 'https://pplns.toncoinpool.io/api/v1/public/network'
    REQUEST_POOL_TIMEOUT = 2

    class << self
      attr_accessor :cache, :last_request_time

      def fetch
        cache.blank? && (pool_data = Pool.last_pool_data).present? && self.cache = pool_data

        current_time = Time.now
        return cache if cache && last_request_time && last_request_time > current_time

        self.last_request_time = current_time + REQUEST_POOL_TIMEOUT.minute
        data = request_json(POOL_INFO_URL, log_text: '|pool|')
        self.cache = Pool.from_data(data) if data.present?
        cache
      rescue StandardError => e
        log e.message
        log e.backtrace
        log 'Error in fetch pool info'
        Pool.last_pool_data
      end
    end
  end
end
