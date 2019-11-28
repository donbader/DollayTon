# frozen_string_literal: true

module Batch
  class CoreyBatch
    include AASM

    PRICE_HISTORY_MIN_SIZE = 30
    MAX_MARGIN = 20
    MIN_MARGIN = 2

    attr_reader :bid_history, :ask_history, :current_order, :last_order

    def initialize
      @ask_history = TempHistory.new('ask_history', data_max_size: 60)
      @bid_history = TempHistory.new('bid_history', data_max_size: 60)

      @current_order = { created_at: Time.zone.now }
      @last_order = { created_at: Time.zone.now }
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

            if should_start_ordering?
              time_elapased = Time.zone.now - @last_order[:created_at]
              @last_order = @current_order.dup

              @current_order = {
                sell: expected_sell_limit_price,
                buy: expected_buy_limit_price,
                created_at: Time.zone.now,
                time_elapased: time_elapased,
              }
            end
          }

        # transitions \
        #   from: :gathering_price_history,
        #   to: :completed,
        #   if: :should_restart?

        # transitions \
        #   from: :gathering_price_history,
        #   to: :gathering_price_history,
        #   after: :process_batch
      end

      event :complete, guard: :can_wrap_up_orders? do
        transitions \
          from: %i[gathering_price_history processing],
          to: :completed,
          after: :cancel_useless_waiting_order
      end
    end

    def process_batch(min_ask, max_bid); end

    #
    # Helpers
    #
    def expected_sell_limit_price
      ask_history.most_frequent.keys.max
    end

    def expected_buy_limit_price
      bid_history.most_frequent.keys.min
    end

    def should_start_ordering?
      (expected_sell_limit_price - expected_buy_limit_price) >= MIN_MARGIN
    end

    def should_keep_gathering?(_min_ask, _max_bid)
      true
    end

    def should_restart?(_current_market_price)
      ask_history.max - bid_history.min > MAX_MARGIN
    end

    # =============
    def inspect
      [
        '',
        "[#{self.class}]______________________________".green,
        "[[#{aasm.current_state}]]".yellow,
        ask_history.inspect,
        bid_history.inspect,
        {
          current_order: @current_order,
          last_order: @last_order,
          expected_buy_limit_price: expected_buy_limit_price,
          expected_sell_limit_price: expected_sell_limit_price
        }.awesome_inspect(indent: -4, index: false, ruby19_syntax: true),
        '________________________________________________'.green
      ].join("\n")
    end
  end
end
