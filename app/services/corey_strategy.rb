# frozen_string_literal: true

class CoreyStrategy
  attr_reader :current_price_data, :trader
  attr_reader :ask_history, :bid_history
  attr_reader :current_order, :last_order

  def self.shared
    @shared ||= OpenStruct.new(
      ask_history: TempHistory.new('ask_history', data_max_size: 60),
      bid_history: TempHistory.new('bid_history', data_max_size: 60),
      current_order: { created_at: Time.zone.now },
      last_order: { created_at: Time.zone.now }
    )
  end
  delegate :shared, to: :class

  def initialize(trader)
    # Freeze the price data
    @current_price_data = trader.current_price_data.dup
    @trader = trader
  end

  def price_of(data, index = 0)
    data[index].first.to_d
  end

  def estimated_market_price
    (min_ask + max_bid) / 2
  end

  def min_ask
    price_of(current_price_data['a'], 0)
  end

  def max_bid
    price_of(current_price_data['b'], 0)
  end

  def place_order(buy:, sell:)
    time_elapased = Time.zone.now - shared.last_order[:created_at]
    shared.last_order = shared.current_order.dup

    shared.current_order = {
      sell: sell,
      buy: buy,
      created_at: Time.zone.now,
      time_elapased: time_elapased
    }
  end

  def perform
    shared.ask_history.insert(min_ask)
    shared.bid_history.insert(max_bid)

    place_order(
      buy: 10,
      sell: 100,
    )

    report if trader.debugging?(:strategy)
  end

  def report
    # Divider
    puts '-' * 70

    ap(shared.ask_history)
    ap(shared.bid_history)

    ap(
      {
        market_price: "[#{estimated_market_price}] --- #{max_bid} .. #{min_ask}",
        current_order: shared.current_order,
        last_order: shared.last_order
      },
      indent: -4, index: false, ruby19_syntax: true
    )
  end
end
