# frozen_string_literal: true

class ProfitStats
  attr_accessor :my_hashrate, :start_t_s, :end_t_s, :start_balance, :end_balance, :user

  def initialize(*args, user:)
    @my_hashrate = args[0].to_f
    @start_t_s = args[1]
    @start_balance = args[2].to_f
    @end_t_s = args[3]
    @end_balance = args[4].to_f
    @user = user
  end

  def calculate
    start_t = Time.parse(start_t_s)
    end_t = Time.parse(end_t_s)
    distance_h = (end_t - start_t).seconds.in_hours # distance in hours
    balance_delta = end_balance - start_balance

    real_tons_in_hour = balance_delta / distance_h # tons in 1 hour
    real_tons_in_day = real_tons_in_hour * 24 # real tons in 24 hour / 1 day
    calculated_profit_in_day_for_gh = real_tons_in_day / my_hashrate
    [distance_h, balance_delta, real_tons_in_hour, real_tons_in_day, calculated_profit_in_day_for_gh]
  end

  def to_text
    distance_h, balance_delta, real_tons_in_hour, expected_tons_in_day, calculated_profit_in_day_for_gh = calculate
    time_distance = just_time(Time.now - distance_h.hours)
    user.t('profit_stats',
           my_hashrate: b(my_hashrate),
           start_t_s: b(start_t_s),
           end_t_s: b(end_t_s),
           start_balance: b(start_balance),
           end_balance: b(end_balance),
           time_distance: b(time_distance),
           balance_delta: b(balance_delta.round(4)),
           real_tons_in_hour: b(real_tons_in_hour.round(4)),
           expected_tons_in_day: b(expected_tons_in_day.round(4)),
           calculated_profit_in_day_for_gh: b(calculated_profit_in_day_for_gh.round(4)))
  end
end
