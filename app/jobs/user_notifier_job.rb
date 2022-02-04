# frozen_string_literal: true

class UserNotifierJob < ApplicationJob
  queue_as :default

  def perform(tg_id, chat_id, text)
    Sender.send_message(tg_id, chat_id, text)
    log "User notified #{tg_id}"
  end
end
