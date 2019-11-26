class CoreyStrategy
  def self.perform(current_price_data, trader)
    # Predefine here first
    trader.env[:profit_max] = 10
    trader.env[:time_scope] = 5.minute
    trader.env[:current_slope] = 1.to_d
    trader.env[:previous_market_price] = 7000
    trader.env[:orders] = []

    return unless trader.env[:profit_max].is_a?(Numeric)
    return unless trader.env[:time_scope].is_a?(ActiveSupport::Duration)
    return unless trader.env[:current_slope].is_a?(Numeric)
    return unless trader.env[:previous_market_price].is_a?(Numeric)
    return unless trader.env[:orders].empty?

    slope = trader.env[:current_slope]
    previous_market_price = trader.env[:previous_market_price]
    current_market_price = (price_of(current_price_data["a"]) + price_of(current_price_data["b"])) / 2

    if slope > 0
      puts "Buy at market_price #{current_market_price}"
      puts "Close it at: #{predict_future_market_price(previous_market_price, current_market_price, slope)}"
    else
      puts "Sell at market_price #{current_market_price}"
      puts "Close it at: #{predict_future_market_price(previous_market_price, current_market_price, slope)}"
    end
  end

  def self.price_of(data, index = 0)
    data[index].first.to_d
  end

  def self.predict_future_market_price(previous_price, current_price, slope)
    current_price + 50
  end
end
