class CoreyStrategy
  COLLECTION_MAX_SIZE = 100

  attr_reader :current_price_data, :trader

  def initialize(current_price_data, trader)
    @current_price_data = current_price_data
    @trader = trader
  end

  def price_of(data, index = 0)
    data[index].first.to_d
  end

  def current_market_price
    @current_market_price ||= (price_of(current_price_data['a']) + price_of(current_price_data['b'])) / 2
  end

  def current_batch
    trader.env[:batch]
  end

  def min_ask
    current_price_data['a'].first.first.to_d
  end

  def max_bid
    current_price_data['b'].first.first.to_d
  end

  def may_complete_order?(order)
    return false unless order.waiting?

    result =
      if order.bid?
        order.price > min_ask
      else
        order.price < max_bid
      end

    result = !result if order.is_a?(StopLossOrder)
    result
  end

  def perform
    if current_batch.gathering_price_history?
      current_batch.process(min_ask, max_bid)
    elsif current_batch.processing?
    elsif current_batch.completed?
      trader.env[:completed_batches] << current_batch
      trader.env[:batch] = current_batch.class.new
    end

    current_batch
  end

  def report_price
    ap({
      "min_ask" => min_ask,
      "max_bid" => max_bid,
      sell_limit: current_batch.sell_limit.price,
      buy_limit: current_batch.buy_limit.price,
      sell_stop_loss: current_batch.sell_limit.stop_loss_order.price,
      buy_stop_loss: current_batch.buy_limit.stop_loss_order.price,
    }.sort_by(&:last).reverse)
  end
end
