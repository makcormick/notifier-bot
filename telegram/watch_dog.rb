# frozen_string_literal: true

class WatchDog
  SKIP_FOR_ERRORS = [Faraday::ConnectionFailed].freeze
  DEFAULT_TRIES_COUNT = 50
  SLEEP_TIMEOUT = 5 # seconds

  @tries = DEFAULT_TRIES_COUNT

  class << self
    attr_accessor :tries, :start

    def decrease_tries
      @tries -= 1
    end

    def reload_when_error(watched_class)
      loop do
        begin
          watched_class.go
        rescue StandardError => e
          watched_class.on_global_error

          center_log 'WATCHDOG DETECT'
          log e.class
          log e.message

          if SKIP_FOR_ERRORS.any? { e.is_a?(_1) }
            sleep(SLEEP_TIMEOUT)
            self.tries = DEFAULT_TRIES_COUNT
          else
            center_log 'Full message'
            log e.full_message
          end

          center_log 'WATCHDOG END'
        end

        decrease_tries
        log "Global error! Try to restart. Try count left: #{tries}"
        break if tries.zero?
      end
    end
  end
end
