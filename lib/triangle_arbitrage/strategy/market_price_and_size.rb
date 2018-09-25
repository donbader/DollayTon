module TriangleArbitrage
  module Strategy
    MAX_INVEST_AMOUNT = 999_999_999_999

    class MarketPriceAndSize < Strategy::Base
      def calculate(max_invest_amount: MAX_INVEST_AMOUNT, refresh: true)
        result = [
          calculate_triangle(@base, @coin1, @coin2, refresh: refresh),
          calculate_triangle(@base, @coin2, @coin1, refresh: false),
        ].max_by { |direction| direction[:exchanged_percentage] }

        max_invest_amount = result[:orders].first[:max_size] / result[:orders].first[:exchange_rate]
        invested_amount = [max_invest_amount, max_invest_amount].min
        profit = invested_amount * (result[:exchanged_percentage] - 1)

        result[:orders] = assign_invest_size(result[:orders], invested_amount)

        result.merge(
          max_invest_amount: "#{max_invest_amount} #{@base}",
          invested_amount: "#{invested_amount} #{@base}",
          profit: profit,
        )
      end

      def calculate_triangle(*coins, refresh: false)
        result = {
          orders: [],
          exchanged_percentage: 1,
        }

        coins.each_with_index do |coin, i|
          next_coin = coins[(i + 1) % coins.size]
          order = better_order(coin, next_coin, refresh: refresh)
          result[:orders] << order
          result[:exchanged_percentage] *= order[:exchange_rate]
        end

        result[:orders] = assign_max_size(result[:orders])

        result
      end

      def better_order(source, dest, refresh: false)
        # TODO: GET Better order from different API
        orders = @clients.map { |client| client.orderbook_price(source, dest, refresh: refresh) }
        orders.max_by { |order| order[:exchange_rate] }
      end

      def assign_max_size(orders)
        temp_base_values = orders.map do |order|
          if order[:method] == :buy
            order[:stock] / order[:exchange_rate]
          else
            order[:stock]
          end
        end

        min_base_value = [
          temp_base_values.first,
          temp_base_values.second / orders.first[:exchange_rate],
          temp_base_values.third / (orders.second[:exchange_rate] * orders.first[:exchange_rate]),
        ].min

        reverted_base_values = [
          min_base_value,
          min_base_value * orders.first[:exchange_rate],
          min_base_value * (orders.second[:exchange_rate] * orders.first[:exchange_rate]),
        ]

        orders.each_with_index.map do |order, i|
          if order[:method] == :buy
            order.merge(max_size: reverted_base_values[i] * order[:exchange_rate])
          else
            order.merge(max_size: reverted_base_values[i])
          end
        end
      end

      def assign_invest_size(orders, invested_amount)
        max_invest_amount = orders.first[:max_size] / orders.first[:exchange_rate]
        orders.map do |order|
          order.merge(size: order[:max_size] * (invested_amount.to_f / max_invest_amount))
        end
      end
    end
  end
end
