# frozen_string_literal: true

module Api
  module Price
    class Base
      REQUEST_PRICE_TIMEOUT = 1

      class << self
        attr_accessor :cached_price, :last_price_request_time

        def price
          return cached_price if cached_price && last_price_request_time && last_price_request_time > Time.now

          set_new_last_price_request_time

          puts "#{self} price next in #{last_price_request_time}"
          self.cached_price = request_price
        end

        private

        def set_new_last_price_request_time
          self.last_price_request_time = Time.now + REQUEST_PRICE_TIMEOUT.minutes
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
