# frozen_string_literal: true

class Looper
  class << self
    def add_user(user)
      if user.notify_solution
        log "#{user.debug_user_info} already notified"
        false
      else
        user.update(notify_solution: true)
        log "#{user.debug_user_info} notify for new solution"
        true
      end
    end

    def remove_user(user)
      user.update(notify_solution: false)
      log "#{user.debug_user_info} stop notify for user"
    end

    attr_accessor :process_store

    def stop(id)
      return unless process_store[id]

      process_store[id].kill
      process_store.delete(id)
    end

    def stop_all
      process_store.each_key do |id|
        process_store[id].kill
        process_store.delete(id)
      end
    end
  end

  TRY_PERIOD = 1 # minutes
  THREAD_SLEEP_PERIOD = 5 # seconds

  @process_store = {}

  attr_accessor :id, :next_iteration_time, :thread, :period

  def initialize(id)
    @id = id
    @next_iteration_time = Time.now
  end

  def start(custom_period = TRY_PERIOD)
    self.period = custom_period
    self.class.stop(id)

    self.class.process_store[id] = @thread = Thread.new do
      loop do
        next sleep(THREAD_SLEEP_PERIOD) if @next_iteration_time > Time.now

        yield

        @next_iteration_time += @period.minutes
      end
    end
  end
end
