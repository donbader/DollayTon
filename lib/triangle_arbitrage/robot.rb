# TriangleArbitrage::Robot.new("USDT", "ETH", "BTC").run(1000)
module TriangleArbitrage
  class Robot
    def initialize(base, coin1, coin2)
      @balances = {}
      @base = base
      @coin1 = coin1
      @coin2 = coin2

      # FIXME: only use cobinhood for now
      @cobinhood = Client::Cobinhood.baimao
    end

    def run(fund)
      # FIXME: compare the price
      calculate_triangle(fund, @base, @coin1, @coin2)
      calculate_triangle(fund, @base, @coin2, @coin1)

      @cobinhood.print_cache
    end

    def calculate_triangle(fund, *coins)
      result = {
        exchanged_fund: fund,
        orders: [],
      }

      coins.each_with_index do |coin, i|
        next_coin = coins[(i + 1) % coins.size]
        result = calculate_after_exchange(result, coin, next_coin)
      end

      ap result
      result
    end

    def calculate_after_exchange(prev_result, source, dest)
      order = better_order(source, dest)
      result = prev_result.dup

      result[:exchanged_fund] = prev_result[:exchanged_fund] / order[:exchange_rate]
      result[:orders] << order.except(:exchange_rate).merge(
        size: order[:method] == :sell ? prev_result[:exchanged_fund] : result[:exchanged_fund],
      )

      result
    end

    def better_order(source, dest)
      # TODO: GET Better order from different API
      @cobinhood.order_book_price(source, dest)
    end
  end
end
