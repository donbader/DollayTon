module Client
  class Cobinhood < Client::Base
    attr_reader :api
    PLACE_ORDER_ENABLED = ENV["PLACE_ORDER"]
    # FIXME: hard-coded for now
    PAIRS = [
      "ETH-USDT",
      "BTC-USDT",
      "ETH-BTC",
    ]

    TRADING_TYPE = {
      sell: :asks,
      buy: :bids,
    }

    def self.corey
      api_key = YAML.load_file("secrets.yml")["COBINHOOD"]["API_KEY"]
      new(api_key: api_key)
    end

    def initialize(api_key: nil)
      super
      @api = CobinhoodApi.new(api_key: api_key)
    end

    # Client::Cobinhood.new.orderbook_price("USDT", "ETH", refresh: false)
    def orderbook_price(source, dest, refresh: false)
      pair = find_pair(source, dest)

      if refresh || cache[pair[:name]].nil?
        store_cache(pair[:name], @api.get_market_order_book(pair[:name], 1))
      end

      type = pair[:reversed] ? :bids : :asks

      price = cache[pair[:name]][type].first["price"]

      exchange_rate = pair[:reversed] ? price : 1.0 / price

      stock = cache[pair[:name]][type].first["size"] * cache[pair[:name]][type].first["count"]

      {
        client: self,
        pair_name: pair[:name],
        price: price,
        exchange_rate: exchange_rate,
        method: pair[:reversed] ? :sell : :buy,
        stock: stock,
      }
    end

    def available_balance(dest, refresh: false)
      if refresh || cache[dest].nil?
        cache[dest] = @api.get_ledger(dest).first["balance"].to_f
      end

      cache[dest]
    end

    def place_order!(pair_name, method, price, size)
      method = method == :buy ? :bid : :ask
      print [self.class.name, pair_name, method, price, size].inspect

      order = nil
      if PLACE_ORDER_ENABLED
        while order.nil?
          order = @api.place_order(pair_name, method, "limit", size, price)

          break unless order.nil?
          print "."
        end

        print 'success'
      end

      puts
      ap order
    end

    def get_market_price
      # => {"trading_pair_id"=>"ETH-USDT",
      # "timestamp"=>1538400720000,
      # "24h_high"=>"238.46",
      # "24h_low"=>"226.72",
      # "24h_open"=>"236.53",
      # "24h_volume"=>"1680.9346363399998",
      # "last_trade_price"=>"229.59",
      # "highest_bid"=>"229.25",
      # "lowest_ask"=>"230.23"}

      @api.get_ticker("ETH-USDT")["last_trade_price"].to_f
    end

    private def find_pair(source, dest)
      name = PAIRS.find { |p| p == "#{dest}-#{source}" }
      return {name: name, reversed: false} if name

      name = PAIRS.find { |p| p == "#{source}-#{dest}" }
      return {name: name, reversed: true} if name

      raise "No such pair for #{dest}-#{source}"
    end
  end
end
