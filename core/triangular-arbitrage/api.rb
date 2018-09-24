# CobinhoodApi
# MaxApi

# features
# get market order book
# place order
# get ledger

class Api
  SECRETS = YAML.load_file("../../secrets.yml")

  EXCHANGES = {
    Cobinhood: "COBINHOOD",
    Max: "MAX"
  }

  def initialize(exchange)
    @exchange = EXCHANGES[exchange.to_sym]
    @api = CobinhoodApi.new(api_key: SECRETS["#{@exchange}_API_KEY"])
  end

  def get_market_order_book(pair, limit)
    @api.get_market_order_book(pair, limit)
  end

  def place_order(pair, trading_type, order_type, size, price)
    @api.place_order(pair, trading_type, order_type, size, price)
  end

  def get_available_balance(coin)
    @api.get_ledger(coin).first["balance"]
  end
end
