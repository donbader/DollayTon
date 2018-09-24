module Client
  class Max < Client::Base
    # FIXME: hard-coded for now
    PAIRS = [
      "ethusdt",
      "btcusdt",
      "ethbtc",
    ]

    TRADING_TYPE = {
      sell: :asks,
      buy: :bids,
    }

    def self.baimao
      # api_key = YAML.load_file("secrets.yml")["MAX"]["API_KEY"]
      # new(api_key)
      api_key = nil
      new(api_key: api_key)
    end

    def initialize(api_key: nil)
      super
      # @header = { api: api_key }
    end

    # Client::Max.new.orderbook_price("USDT", "ETH", refresh: false)
    def orderbook_price(source, dest, refresh: false)
      pair = find_pair(source, dest)

      if refresh || cache[pair[:name]].nil?
        store_cache(
          pair[:name],
          HTTParty.get(
            'https://max-api.maicoin.com/api/v2/order_book',
            query: {
              market: pair[:name],
              asks_limit: 1,
              bids_limit: 1
            },
          )
        )
      end

      type = pair[:reversed] ? "bids" : "asks"

      price = cache[pair[:name]][type].first["price"].to_f

      exchange_rate = pair[:reversed] ? price.to_f : 1.0 / price.to_f

      stock = cache[pair[:name]][type].first["remaining_volume"].to_f

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
      puts [self.class.name, pair_name, method, price, size].inspect
    end

    private def find_pair(source, dest)
      name = PAIRS.find { |p| p == "#{dest}#{source}".downcase }
      return {name: name, reversed: false} if name

      name = PAIRS.find { |p| p == "#{source}#{dest}".downcase }
      return {name: name, reversed: true} if name

      raise "No such pair for #{dest}#{source}"
    end
  end
end
