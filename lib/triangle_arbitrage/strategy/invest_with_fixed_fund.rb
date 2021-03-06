module TriangleArbitrage
  module Strategy
    class InvestWithFixedFund < Strategy::Base
      def calculate(min_fund:, max_fund:, refresh: true)
        result = [
          calculate_triangle(max_fund, @base, @coin1, @coin2, refresh: refresh),
          calculate_triangle(max_fund, @base, @coin2, @coin1, refresh: false),
        ].max_by { |direction| direction[:exchanged_percentage] }

        invested_amount = max_fund
        invested_amount = 0 if invested_amount < min_fund

        profit = invested_amount * (result[:exchanged_percentage] - 1)

        result.merge(
          max_invest_amount: "#{max_fund} #{@base}",
          invested_amount: "#{invested_amount} #{@base}",
          profit: profit,
        )
      end

      def calculate_triangle(max_fund, *coins, refresh: false)
        result = {
          orders: [],
          exchanged_percentage: 1,
        }

        prev_exchanged_fund = max_fund

        coins.each_with_index do |coin, i|
          next_coin = coins[(i + 1) % coins.size]
          order = better_order(coin, next_coin, refresh: refresh)

          result[:exchanged_percentage] *= order[:exchange_rate]
          result[:orders] << order.merge(
            size: order[:method] == :sell ? prev_exchanged_fund : prev_exchanged_fund * order[:exchange_rate],
          )
          prev_exchanged_fund *= order[:exchange_rate]
        end

        result
      end

      def better_order(source, dest, refresh: false)
        # TODO: GET Better order from different API
        orders = @clients.map { |client| client.orderbook_price(source, dest, refresh: refresh) }
        orders.max_by { |order| order[:exchange_rate] }
      end
    end
  end
end
