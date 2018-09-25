module Client
  class Binance < Client::Base
    include Singleton
    PLACE_ORDER_ENABLED = ENV["PLACE_ORDER"]
    FEE_RATE = 0.001
    PAIRS = [
      "ETHBTC",
      "ETHUSDT",
      "BTCUSDT",
    ]

    def initialize
      super
      secrets = YAML.load_file("secrets.yml")["BINANCE"]
      api_key = secrets["API_KEY"]
      secret_key = secrets["SECRET_KEY"]
      @rest_api = ::Binance::Client::REST.new(api_key: api_key, secret_key: secret_key)
      run_websocket_client
      sleep(3) # Sleep 3 for waiting first data coming in
    end

    # Client::Binance.new.orderbook_price("USDT", "ETH", refresh: false)
    def orderbook_price(source, dest, refresh: false)
      pair = find_pair(source, dest)
      type = pair[:reversed] ? "bids" : "asks"

      if refresh || cache[pair[:name]][type].nil?
        store_cache(pair[:name], @websocket_cache[:orderbook_price][pair[:name]].dup)
      end

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
      if PLACE_ORDER_ENABLED
        order = @rest_api.create_order!(
          symbol: pair_name,
          side: method.upcase,
          type: "LIMIT",
          price: price,
          quantity: size,
          time_in_force: 'GTC',
        )
      else
        puts [self.class.name, pair_name, method, price, size].inspect
      end
    end

    # Store data into @websocket_cache
    private def run_websocket_client
      @websocket = ::Binance::Client::WebSocket.new
      @websocket_cache = { orderbook_price: {} }
      @websocket_thread = Thread.new do
        EM.run do
          # Listen to all interested coins
          PAIRS.each do |pair_name|
            @websocket.partial_book_depth(symbol: pair_name, level: "5", methods: {
              message: proc { |e|
                @websocket_cache[:orderbook_price][pair_name] = JSON.parse(e.data)
              },
            })
          end
        end
      end
    end

    private def find_pair(source, dest)
      name = PAIRS.find { |p| p == "#{dest}#{source}" }
      return { name: name, reversed: false } if name

      name = PAIRS.find { |p| p == "#{source}#{dest}" }
      return { name: name, reversed: true } if name

      raise "No such pair for #{dest}-#{source}"
    end
  end
end
