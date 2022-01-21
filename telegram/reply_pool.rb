# frozen_string_literal: true

class ReplyPool
  @pool = {}

  class << self
    attr_accessor :pool, :bot

    def for(chat_id, &block)
      pool[chat_id] = block
    end

    def call_with(chat_id, reply)
      pool.delete(chat_id)[reply]
    end
  end

  attr_accessor :user, :chat_id

  def initialize(user)
    @user = user
    @chat_id = user.chat_id
  end

  def change_time_zone
    self.class.for(chat_id) do |reply|
      sender = Sender.new(reply, user)

      is_integer = integer?(reply.text)
      time_zone = reply.text.to_i

      unless is_integer && time_zone > -13 && time_zone < 14
        sender.with_keyboard_close(user.t('invalid_tz'))
        next ReplyPool.new(user).change_time_zone
      end

      log "#{user.debug_user_info} changed time zone offset to #{time_zone}"
      user.update(time_zone: time_zone)
      sender.settings_response(user.t('tz_was_changed', time_zone: time_zone))
    end
  end

  def profit_calculating
    self.class.for(chat_id) do |reply|
      sender = Sender.new(reply, user)

      parsed = reply.text.split("\n").map(&:strip)
      args = [parsed[0], *parsed[1].split('-').map(&:strip), *parsed[2].split('-').map(&:strip)]
      text = ProfitStats.new(*args, user: user).to_text
      log "#{user.debug_user_info} profit_calculating #{parsed}"
      sender.default_response(text, with_replacing: false)
    rescue StandardError => e
      log "#{e.message}\n#{user.debug_user_info} wrong parameters in profit_calculating"
      sender.default_response(user.t('wrong_parameters'), with_replacing: false)
    end
  end

  def set_wallet
    self.class.for(chat_id) do |reply|
      sender = Sender.new(reply, user)

      user.update(wallet: reply.text)
      sender.default_response(user.t('wallet_was_added'), with_replacing: false)
    end
  end
end
