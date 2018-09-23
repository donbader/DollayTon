# TriangleArbitrage::Robot.new("USDT", "ETH", "BTC").run(1000)
DEBUG = false
module TriangleArbitrage
  class Robot

    def self.hi
      time_start = Time.now
      earned = 0

      while Time.now - time_start < 3600
        result = TriangleArbitrage::Robot.new("USDT", "ETH", "BTC").run(1000)

        earned += result[:profit] if result[:profit] > 0
        ap result
        puts "earned: #{earned}, Time elapsed: #{Time.now - time_start}"
        puts "----------------------------------------------------"
      end
    end

    def initialize(base, coin1, coin2)
      @balances = {}
      @base = base
      @coin1 = coin1
      @coin2 = coin2

      # FIXME: only use cobinhood for now
      @clients = [
        Client::Cobinhood.baimao,
        Client::Binance.corey,
      ]
    end

    def run(fund)
      # FIXME: compare the price
      direction1 = calculate_triangle(fund, @base, @coin1, @coin2)
      ap direction1.except(:orders) if DEBUG
      direction2 = calculate_triangle(fund, @base, @coin2, @coin1)
      ap direction2.except(:orders) if DEBUG

      profit1 = direction1[:exchanged_fund] - fund
      profit2 = direction2[:exchanged_fund] - fund

      if profit1 > profit2
        direction1.merge(profit: profit1)
      else
        direction2.merge(profit: profit2)
      end
      # @binance.print_cache
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

      result
    end

    def calculate_after_exchange(prev_result, source, dest)
      order = better_order(source, dest)
      result = prev_result.dup

      result[:exchanged_fund] = prev_result[:exchanged_fund] * order[:exchange_rate]
      result[:orders] << order.except(:exchange_rate).merge(
        size: order[:method] == :sell ? prev_result[:exchanged_fund] : result[:exchanged_fund],
      )

      result
    end

    def better_order(source, dest)
      # TODO: GET Better order from different API
      orders = @clients.map { |client| client.orderbook_price(source, dest).merge(client: client.class) }
      ap orders if DEBUG
      orders.max_by { |order| order[:exchange_rate] }
    end
  end
end
