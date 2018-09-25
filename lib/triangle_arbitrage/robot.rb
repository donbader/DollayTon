DEBUG = false

module TriangleArbitrage
  class Robot
    MAX_INVEST_AMOUNT = 999_999_999_999

    def self.hi
      bot = TriangleArbitrage::Robot.new("USDT", "ETH", "BTC")
      bot.run(7.hour, max_amount: 100)
    end

    def initialize(base, coin1, coin2)
      @strategy = Strategy::MarketPriceAndSize.new(base, coin1, coin2)
    end

    def run(total_time, max_amount: MAX_INVEST_AMOUNT)
      time_start = Time.now
      earned = 0

      while Time.now - time_start < total_time
        result = @strategy.calculate(max_amount: max_amount, refresh: true)
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
  end
end
