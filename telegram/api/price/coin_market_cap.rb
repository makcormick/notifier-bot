# frozen_string_literal: true

module Api
  module Price
    class CoinMarketCap < Base
      COIN_MARKET_CAP_TON_API = 'https://coinmarketcap.com/currencies/toncoin/'

      class << self
        def api_price
          request_html(COIN_MARKET_CAP_TON_API, log_text: '|price|').css('.priceValue').text.tr('^0-9[.]', '')
        end
      end
    end
  end
end
