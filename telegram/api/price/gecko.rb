# frozen_string_literal: true

module Api
  module Price
    class Gecko < Base
      TON_PRICE_API = 'https://api.coingecko.com/api/v3/simple/price?ids=the-open-network&vs_currencies=usd'

      class << self
        def api_price
          request_json(TON_PRICE_API, log_text: '|price|').dig('the-open-network', 'usd')
        end
      end
    end
  end
end
