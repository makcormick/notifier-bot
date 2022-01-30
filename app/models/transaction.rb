# frozen_string_literal: true

class Transaction < ApplicationRecord
  extend HistoryStore

  SCAN_TIMEOUT = 1

  belongs_to :pool

  default_scope { order(time: :desc) }

  validates :t_hash, uniqueness: true, presence: true

  def self.from_data(data, pool_info)
    create(time: Time.at(data['timestamp']), t_hash: data['hash'], giver: data.dig('received', 'from'),
           pool: pool_info)
  end
end
