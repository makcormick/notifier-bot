# frozen_string_literal: true

class Pool < ApplicationRecord
  serialize :total_shares, Array
  has_many :transactions

  POOL_TIMEOUT = 2
  SOLUTION_REWARD = 100
  COMISSION = 0
  SHARE_DIFF = 200

  class << self
    def last_pool_data
      Pool.order(created_at: :desc).first
    end

    def from_data(data)
      create(hashrate: Service::PoolHashrate.new(data['totalShares']).perform,
             n_difficult: data.fetch('networkDifficulty'),
             last_sol_seq: data['lastBlockSeqno'],
             last_solved_time: Time.parse(data['lastChallengeSolved']),
             total_miners: data['totalMiners'],
             total_shares: data['totalShares'])
    end

    def clear_reward
      SOLUTION_REWARD.to_f * (100 - COMISSION) / 100
    end
  end

  def moment_profit
    24 * 3600 * self.class.clear_reward * (10**9) / n_difficult
  end

  def expected_solutions_in_day_moment
    hours_for_solution = n_difficult.to_f / hashrate / 3600
    (24 / hours_for_solution).round(1)
  end
end
