# frozen_string_literal: true

module Service
  class LastDaySolutions
    attr_accessor :cache

    def initialize
      @cache = {}
    end

    def count(time = Time.now.utc)
      return cache[time] if cache.key?(time)

      result = Transaction.where('time >= ? AND time <= ?', time.beginning_of_day, time).count
      cache[time] = result
    end
  end
end
