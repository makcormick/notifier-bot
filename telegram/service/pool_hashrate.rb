# frozen_string_literal: true

module Service
  class PoolHashrate
    SHARES_PERIOD = 5
    SHARES_DIFF = 200

    attr_accessor :total_shares, :current_time, :shares_period

    def initialize(total_shares, shares_period = SHARES_PERIOD)
      @total_shares = total_shares
      @current_time = Time.now
      @shares_period = shares_period
    end

    def perform(time = 1.hour)
      total_shares.last((time / shares_period.minutes).round).sum * SHARES_DIFF / seconds_range(time) * (10**9)
    end

    private

    def seconds_range(time)
      current_time - round_time(current_time - time)
    end

    def round_time(time, period = shares_period)
      if (new_min = time.min - (time.min % period) + period) > 59
        new_min = 59
      end
      time.change(min: new_min)
    end
  end
end
