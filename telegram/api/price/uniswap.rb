# frozen_string_literal: true

module Api
  module Price
    class Uniswap < Base
      UNISWAP_API = 'https://api.ton.sh/getCoinPrice'

      class << self
        def api_price
          data = request_json(UNISWAP_API, log_text: '|price|')
          data['result'].presence || 0
        end
      end
    end
  end
end
