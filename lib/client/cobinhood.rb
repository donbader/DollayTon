module Client
  class Cobinhood < Client::Base
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

    def self.baimao
      api_key = YAML.load_file("secrets.yml")["COBINHOOD"]["API_KEY"]
      new(api_key)
    end

    def initialize(api_key)
      super
      @api = CobinhoodApi.new(api_key: api_key)
    end

    def order_book_price(source, dest, refresh: false)
      pair = find_pair(source, dest)

      if refresh || cache[pair[:name]].nil?
        cache[pair[:name]] = @api.get_market_order_book(pair[:name], 1)
      end

      type = pair[:reversed] ? :bids : :asks

      price = cache[pair[:name]][type].first["price"]

      exchange_rate = pair[:reversed] ? 1.0 / price : price

      {
        pair_name: pair[:name],
        price: price,
        exchange_rate: exchange_rate,
        method: pair[:reversed] ? :sell : :buy,
      }
    end

    def available_balance(dest, refresh: false)
      if refresh || cache[dest].nil?
        cache[dest] = @api.get_ledger(dest).first["balance"].to_f
      end

      cache[dest]
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

# Client::Cobinhood.
