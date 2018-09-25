
# TriangleArbitrage::Robot.hi(1000, strategy_class: TriangleArbitrage::Strategy::MarketPriceAndSize)
# TriangleArbitrage::Robot.hi(1000, strategy_class: TriangleArbitrage::Strategy::InvestWithFixedFund)
module TriangleArbitrage
  class Robot

    def self.hi(max_invest_amount, strategy_class:)
      bot = TriangleArbitrage::Robot.new("USDT", "ETH", "BTC", strategy_class: strategy_class)
      bot.run(7.hour, max_invest_amount: max_invest_amount)
    end

    def initialize(base, coin1, coin2, strategy_class: Strategy::MarketPriceAndSize)
      @strategy = strategy_class.new(base, coin1, coin2)
    end

    def run(total_time, max_invest_amount:)
      time_start = Time.now
      earned = 0

      while Time.now - time_start < total_time
        result = @strategy.calculate(max_invest_amount: max_invest_amount, refresh: true)
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
