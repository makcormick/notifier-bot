# frozen_string_literal: true

module Api
  module Price
    class Base
      REQUEST_PRICE_TIMEOUT = 1

      class << self
        attr_accessor :cached_price, :next_price_request_time

        def price
          return cached_price if cached_price && next_price_request_time && next_price_request_time > Time.now

          set_new_next_price_request_time

          self.cached_price = request_price
          log "#{self} price #{cached_price} next in #{format_time(next_price_request_time, o_time: true)}"
          cached_price
        end

        def current_price
          cached_price.presence || price
        end

        private

        def set_new_next_price_request_time
          self.next_price_request_time = Time.now + REQUEST_PRICE_TIMEOUT.minutes
        end

        def request_price
          api_price.to_f
        rescue StandardError
          0.0
        end
      end
    end
  end
end
