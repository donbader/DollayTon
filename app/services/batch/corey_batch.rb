# frozen_string_literal: true
module Batch
  class CoreyBatch
    include AASM

    PRICE_HISTORY_MIN_SIZE = 30
    MAX_MARGIN = 20
    MIN_MARGIN = MAX_MARGIN / 3

    attr_reader :bid_history, :ask_history, :buy_limit, :sell_limit

    def initialize
      @ask_history = TempHistory.new("ask_history", data_max_size: 500)
      @bid_history = TempHistory.new("bid_history", data_max_size: 500)
      @buy_limit = nil
      @sell_limit = nil
    end

    aasm do
      state :gathering_price_history, initial: true
      state :processing
      state :completed

      event :process do
        transitions \
          from: :gathering_price_history,
          to: :gathering_price_history,
          if: :should_keep_gathering?,
          after: proc { |min_ask, max_bid|
            ask_history.insert(min_ask)
            bid_history.insert(max_bid)
          }

        transitions \
          from: :gathering_price_history,
          to: :completed,
          if: :should_restart?

        transitions \
          from: :gathering_price_history,
          to: :processing,
          after: :process_batch
      end

      event :complete, guard: :can_wrap_up_orders? do
        transitions \
          from: %i[gathering_price_history processing],
          to: :completed,
          after: :cancel_useless_waiting_order
      end
    end

    def process_batch(min_ask, max_bid)
      # if @buy_limit || @sell_limit
      #   raise "cannot create orders already"
      # end

      # buy_amount = [expected_buy_limit_price, max_bid].min
      # @buy_limit = LimitOrder.create_with_stop_loss!(
      #   bid_history.min,
      #   exchange: "binance",
      #   price: buy_amount,
      #   pair_name: "BTCUSDT",
      #   direction: "bid",
      # )

      # sell_amount = [expected_sell_limit_price, min_ask].max
      # # sell-limit order
      # @sell_limit = LimitOrder.create_with_stop_loss!(
      #   ask_history.max,
      #   exchange: "binance",
      #   price: sell_amount,
      #   pair_name: "BTCUSDT",
      #   direction: "ask",
      # )
    end

    #
    # Helpers
    #
    def expected_sell_limit_price
      ask_history.most_frequent.max
    end

    def expected_buy_limit_price
      bid_history.most_frequent.min
    end

    def should_keep_gathering?(min_ask, max_bid)
      true
    end

    def should_restart?(_current_market_price)
      ask_history.max - bid_history.min > MAX_MARGIN
    end

    def can_wrap_up_orders?
      (!sell_limit.waiting? && !buy_limit.waiting?) || \
        (!sell_limit.stop_loss_order.waiting? && !sell_limit.waiting?) || \
        (!buy_limit.stop_loss_order.waiting? && !buy_limit.waiting?)
    end

    def cancel_useless_waiting_order
      [
        buy_limit,
        sell_limit,
        buy_limit.stop_loss_order,
        sell_limit.stop_loss_order,
      ].select(&:waiting?).each(&:cancelled!)
    end

    # =============
    def inspect
      [
        '',
        "[#{self.class}]______________________________".green,
        "[[#{aasm.current_state}]]".yellow,
        {
          buy_limit: buy_limit&.price,
          sell_limit: sell_limit&.price,
          expected_buy_limit_price: expected_buy_limit_price,
          expected_sell_limit_price: expected_sell_limit_price,
        }.awesome_inspect(indent: -4, index: false, ruby19_syntax: true),
        ask_history.inspect,
        bid_history.inspect,
        "________________________________________________".green
      ].join("\n")
    end
  end
end
