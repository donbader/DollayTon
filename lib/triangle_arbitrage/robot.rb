DEBUG = false

module TriangleArbitrage
  class Robot
    MAX_INVEST_AMOUNT = 999_999_999_999

    def self.hi
      bot = TriangleArbitrage::Robot.new("USDT", "ETH", "BTC")
      bot.run(7.hour, max_amount: 100)
    end

    def initialize(base, coin1, coin2)
      @balances = {}
      @base = base
      @coin1 = coin1
      @coin2 = coin2

      @clients = [
        Client::Cobinhood.baimao,
        Client::Binance.corey,
        Client::Max.baimao,
      ]
    end

    def run(total_time, max_amount: MAX_INVEST_AMOUNT)
      time_start = Time.now
      earned = 0

      while Time.now - time_start < total_time
        result = self.calculate(max_amount: max_amount, refresh: true)
        ap result

        if result[:profit] > 0
          self.place_orders(result[:orders])
          earned += result[:profit]
        end

        puts "earned: #{earned}, Time elapsed: #{Time.now - time_start}"
        puts "----------------------------------------------------"
      end
    end

    def place_orders(orders)
      orders.each do |client:, pair_name:, method:, price:, size:, **_kwargs|
        client.place_order!(pair_name, method, price, size)
      end
    end

    def calculate(max_amount: MAX_INVEST_AMOUNT, refresh: true)
      direction1 = calculate_triangle(@base, @coin1, @coin2, refresh: refresh)
      ap direction1.except(:orders) if DEBUG
      direction2 = calculate_triangle(@base, @coin2, @coin1, refresh: false)
      ap direction2.except(:orders) if DEBUG

      result = [
        calculate_triangle(@base, @coin1, @coin2, refresh: refresh),
        calculate_triangle(@base, @coin2, @coin1, refresh: false),
      ].max_by { |direction| direction[:exchanged_percentage] }

      needed_fund = result[:orders].first[:max_size] / result[:orders].first[:exchange_rate]
      invested_amount = [needed_fund, max_amount].min
      profit = invested_amount * (result[:exchanged_percentage] - 1)

      result[:orders] = assign_invest_size(result[:orders], invested_amount)

      result.merge(
        needed_fund: "#{needed_fund} #{@base}",
        invested_amount: "#{invested_amount} #{@base}",
        profit: profit,
      )
    end

    def calculate_triangle(*coins, refresh: false)
      result = {
        exchanged_percentage: 1,
        orders: [],
      }

      coins.each_with_index do |coin, i|
        next_coin = coins[(i + 1) % coins.size]
        order = better_order(coin, next_coin, refresh: refresh)
        result[:exchanged_percentage] *= order[:exchange_rate]
        result[:orders] << order
      end

      result[:orders] = assign_max_size(result[:orders])

      result
    end

    def better_order(source, dest, refresh: false)
      # TODO: GET Better order from different API
      orders = @clients.map { |client| client.orderbook_price(source, dest, refresh: refresh) }
      ap orders if DEBUG
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
      needed_fund = orders.first[:max_size] / orders.first[:exchange_rate]
      orders.map do |order|
        order.merge(size: order[:max_size] * (invested_amount.to_f / needed_fund))
      end
    end
  end
end
