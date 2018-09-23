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
      api_key = nil
      new(api_key)
    end

    def initialize(api_key)
      super
      @api = CobinhoodApi.new(api_key: api_key)
    end

    def orderbook_price(source, dest, refresh: false)
      pair = find_pair(source, dest)

      if refresh || cache[pair[:name]].nil?
        cache[pair[:name]] = @api.get_market_order_book(pair[:name], 1)
      end

      type = pair[:reversed] ? :bids : :asks

      price = cache[pair[:name]][type].first["price"]

      exchange_rate = pair[:reversed] ? price : 1.0 / price

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

    def place_order!(pair_name, method, price, size)
      method = method == :buy ? :bid : :ask
      order =
        if ENV["PLACE_ORDER"]
          nil
        else
          puts [self.class.name, pair_name, method, price, size].inspect
          123
        end

      while order.nil?
        order = @api.place_order(pair_name, method, "limit", size, price)

        break unless order.nil?
        puts "failed try again"
      end
      puts 'success'
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
