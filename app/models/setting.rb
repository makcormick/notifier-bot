# frozen_string_literal: true

class Setting < ApplicationRecord
  serialize :last_transaction

  def self.sync(num = 0)
    Transaction.next_sync_time = nil
    transaction = Transaction.deep_scan[num]
    self.last_transaction = transaction
  end

  def self.last_transaction
    first_setting.last_transaction || {}
  end

  def self.last_transaction=(transaction)
    first_setting.update(last_transaction: { 'hash' => transaction.t_hash, 'timestamp' => transaction.time,
                                             'giver' => transaction.giver })
  end

  def self.first_setting
    first_or_create
  end
end
