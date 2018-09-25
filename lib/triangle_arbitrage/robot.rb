
# TriangleArbitrage::Robot.hi(50, strategy_class: TriangleArbitrage::Strategy::MarketPriceAndSize)
# TriangleArbitrage::Robot.hi(50, strategy_class: TriangleArbitrage::Strategy::InvestWithFixedFund)
module TriangleArbitrage
  class Robot

    def self.hi(max_fund, strategy_class:)
      bot = TriangleArbitrage::Robot.new("USDT", "ETH", "BTC", strategy_class: strategy_class)
      bot.run(7.hour, min_fund: 30, max_fund: max_fund)
    end

    def initialize(base, coin1, coin2, strategy_class: Strategy::MarketPriceAndSize)
      @strategy = strategy_class.new(base, coin1, coin2)
    end

    def run(total_time, min_fund:, max_fund:)
      time_start = Time.now
      earned = 0

      while Time.now - time_start < total_time
        result = @strategy.calculate(min_fund: min_fund, max_fund: max_fund, refresh: true)
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
