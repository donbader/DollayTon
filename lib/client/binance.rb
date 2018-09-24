module Client
  class Binance < Client::Base
    FEE_RATE = 0.001
    PAIRS = [
      "ETHBTC",
      "ETHUSDT",
      "BTCUSDT",
    ]

    def self.corey
      # api_key = YAML.load_file("secrets.yml")["BINANCE"]["API_KEY"]
      api_key = nil
      new(api_key: api_key)
    end

    def initialize(api_key: nil, secret_key: nil)
      super
      @rest_api = ::Binance::Client::REST.new(api_key: api_key)
    end

    # Client::Binance.new.orderbook_price("USDT", "ETH", refresh: false)
    def orderbook_price(source, dest, refresh: false)
      pair = find_pair(source, dest)

      if refresh || cache[pair[:name]].nil?
        store_cache(pair[:name], @rest_api.depth(symbol: pair[:name], limit: 5))
      end

      type = pair[:reversed] ? "bids" : "asks"

      price = cache[pair[:name]][type].first[0].to_f

      exchange_rate = pair[:reversed] ? price : 1.0 / price
      exchange_rate *= (1 - FEE_RATE) # Fees

      stock = cache[pair[:name]][type].first[1].to_f

      {
        client: self,
        pair_name: pair[:name],
        price: price,
        exchange_rate: exchange_rate,
        method: pair[:reversed] ? :sell : :buy,
        stock: stock,
      }
    end

    def place_order!(pair_name, method, price, size)
      order =
        if ENV["PLACE_ORDER"]
          nil
        else
          puts [self.class.name, pair_name, method, price, size].inspect
          123
        end

      order = @rest_api.create_order!(symbol: pair_name, side: method.upcase, type: "LIMIT") if order.nil?
    end

    private def find_pair(source, dest)
      name = PAIRS.find { |p| p == "#{dest}#{source}" }
      return {name: name, reversed: false} if name

      name = PAIRS.find { |p| p == "#{source}#{dest}" }
      return {name: name, reversed: true} if name

      raise "No such pair for #{dest}-#{source}"
    end
  end
end
