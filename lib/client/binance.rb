module Client
  class Binance < Client::Base
    PAIRS = [
      "ETHBTC",
      "ETHUSDT",
      "BTCUSDT",
    ]

    def self.corey
      api_key = YAML.load_file("secrets.yml")["BINANCE"]["API_KEY"]
      new(api_key)
    end

    def initialize(api_key, secret_key = nil)
      super
      @rest_api = ::Binance::Client::REST.new(api_key: api_key)
    end

    def orderbook_price(source, dest, refresh: false)
      pair = find_pair(source, dest)

      if refresh || cache[pair[:name]].nil?
        cache[pair[:name]] = @rest_api.depth(symbol: pair[:name], limit: 5)
      end

      type = pair[:reversed] ? "bids" : "asks"

      price = cache[pair[:name]][type].first.first.to_f

      exchange_rate = pair[:reversed] ? price : 1.0 / price
      exchange_rate *= 0.999 # Fees

      {
        pair_name: pair[:name],
        price: price,
        exchange_rate: exchange_rate,
        method: pair[:reversed] ? :sell : :buy,
      }
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
