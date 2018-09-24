DEBUG = false

module TriangleArbitrage
  class Robot

    def self.hi
      bot = TriangleArbitrage::Robot.new("USDT", "ETH", "BTC")
      bot.run(1000, 7.hour)
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

    def run(fund, total_time)
      time_start = Time.now
      earned = 0

      while Time.now - time_start < total_time
        result = self.calculate(fund, refresh: true)
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
      orders.each do |client:, pair_name:, method:, price:, size:|
        client.place_order!(pair_name, method, price, size)
      end
    end

    def calculate(fund, refresh: true)
      direction1 = calculate_triangle(fund, @base, @coin1, @coin2, refresh: refresh)
      ap direction1.except(:orders) if DEBUG
      direction2 = calculate_triangle(fund, @base, @coin2, @coin1, refresh: false)
      ap direction2.except(:orders) if DEBUG

      profit1 = direction1[:exchanged_fund] - fund
      profit2 = direction2[:exchanged_fund] - fund

      if profit1 > profit2
        direction1.merge(profit: profit1)
      else
        direction2.merge(profit: profit2)
      end
    end

    def calculate_triangle(fund, *coins, refresh: false)
      result = {
        exchanged_fund: fund,
        orders: [],
      }

      coins.each_with_index do |coin, i|
        next_coin = coins[(i + 1) % coins.size]
        result = calculate_after_exchange(result, coin, next_coin, refresh: refresh)
      end

      result
    end

    def calculate_after_exchange(prev_result, source, dest, refresh: false)
      order = better_order(source, dest, refresh: refresh)
      result = prev_result.dup

      result[:exchanged_fund] = prev_result[:exchanged_fund] * order[:exchange_rate]
      result[:orders] << order.except(:exchange_rate).merge(
        size: order[:method] == :sell ? prev_result[:exchanged_fund] : result[:exchanged_fund],
      )

      result
    end

    def better_order(source, dest, refresh: false)
      # TODO: GET Better order from different API
      orders = @clients.map { |client| client.orderbook_price(source, dest, refresh: refresh) }
      ap orders if DEBUG
      orders.max_by { |order| order[:exchange_rate] }
    end
  end
end
