# frozen_string_literal: true

class UserNotifierJob < ApplicationJob
  queue_as :default

  def perform(tg_id, chat_id, text)
    ms_time = Benchmark.realtime do
      Sender.send_message(tg_id, chat_id, text)
    end

    log "User notified #{tg_id} with #{ms_time} seconds"
  end
end
