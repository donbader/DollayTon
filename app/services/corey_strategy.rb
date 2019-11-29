class CoreyStrategy
  COLLECTION_MAX_SIZE = 100

  attr_reader :current_price_data, :trader

  def initialize(trader)
    # Freeze the price data
    @current_price_data = trader.current_price_data.dup
    @trader = trader
  end

  def price_of(data, index = 0)
    data[index].first.to_d
  end

  def current_market_price
    (min_ask + max_bid) / 2
  end

  def batch
    trader.env[:batch]
  end

  def min_ask
    current_price_data['a'].first.first.to_d
  end

  def max_bid
    current_price_data['b'].first.first.to_d
  end

  def perform
    batch.process(min_ask, max_bid)
    report_price

    batch
  end

  def report_price
    return unless trader.debugging?(:strategy)

    ap batch
  end
end
