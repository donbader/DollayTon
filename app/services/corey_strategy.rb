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
    # not to place duplicated order
    return if buy == shared.last_order[:buy] && sell == shared.last_order[:sell]

    time_elapased = Time.zone.now - shared.last_order[:created_at]
    shared.last_order = shared.current_order.dup

    shared.current_order = {
      sell: sell,
      buy: buy,
      created_at: Time.zone.now,
      time_elapased: time_elapased
    }
  end

  def good_price_to_buy
    price = shared.bid_history.min.to_i
    price if price == shared.ask_history.min.to_i
  end

  def good_price_to_sell
    price = shared.bid_history.max.to_i
    price if price == shared.ask_history.max.to_i
  end

  def should_place_order?(buy, sell)
    return unless buy && sell
    (sell - buy) > 3
  end

  def perform
    shared.ask_history.insert(min_ask)
    shared.bid_history.insert(max_bid)

    buy = good_price_to_buy
    sell = good_price_to_sell

    if should_place_order?(buy, sell)
      place_order(
        buy: buy,
        sell: sell,
      )
    else
      place_order(
        buy: nil,
        sell: nil,
      )
    end

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
