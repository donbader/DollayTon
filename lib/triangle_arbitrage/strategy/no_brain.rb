module TriangleArbitrage
  module Strategy
    MAX_INVEST_AMOUNT = 999_999_999_999
    MIN_INVEST_AMOUNT = 30
    BIAS = 0.1
    FEES = 0.001

    class NoBrain < Strategy::Base
      def calculate(min_fund: MIN_INVEST_AMOUNT, max_fund: MAX_INVEST_AMOUNT, refresh: true)
        client = Client::Cobinhood.corey
        higher_price = client.orderbook_price("USDT", "ETH", refresh: false)[:price]
        lower_price = client.orderbook_price("ETH", "USDT", refresh: refresh)[:price]
        ap client.orderbook_price("USDT", "ETH", refresh: false)
        ap client.orderbook_price("ETH", "USDT", refresh: false)
        client.api.get_market_order_book("ETH-USDT", 20))
        client.api.get_market_order_book("ETH-USDT", 20))
        mid_price = (higher_price + lower_price) / 2.0
        buy_price = mid_price - BIAS
        sell_price = mid_price + BIAS

        invested_amount = max_fund
        size = invested_amount / buy_price
        profit = (sell_price * size) - (buy_price * size)  #- invested_amount * FEES * 2

        {
          orders: [
            {
              client: client,
              pair_name: "ETH-USDT",
              price: buy_price,
              method: :buy,
              size: size,
            },
            {
              client: client,
              pair_name: "ETH-USDT",
              price: sell_price,
              method: :sell,
              size: size,
            },
          ],
          exchanged_percentage: 1 + profit / invested_amount,
          max_invest_amount: max_fund,
          invested_fund: invested_amount,
          profit: profit,
        }
      end
    end
  end
end
