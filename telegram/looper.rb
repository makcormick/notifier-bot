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
  DELAY = 0.5
  THREAD_SLEEP_PERIOD = 5 # seconds

  @process_store = {}

  attr_accessor :id, :next_iteration_time, :thread, :period, :delay

  def initialize(id)
    @id = id
  end

  def start(custom_period = TRY_PERIOD, delay: 0, abort_on_exception: true)
    self.period = custom_period.minutes
    self.delay = delay.minutes
    self.next_iteration_time = Time.now + self.delay
    self.class.stop(id)

    self.class.process_store[id] = @thread = Thread.new do
      sleep(@delay) if @delay.positive?

      loop do
        current_time = Time.now
        next sleep(THREAD_SLEEP_PERIOD) if @next_iteration_time > current_time

        yield

        @next_iteration_time = current_time + @period
      end
    end

    @thread.abort_on_exception = abort_on_exception
  end
end
