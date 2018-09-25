module Client
  class Base
    def initialize(*args, **kwargs)
      @cache = ActiveSupport::HashWithIndifferentAccess.new
    end

    def cache
      @cache[caller[0][/`.*'/][1..-2]] ||= {}
    end

    def store_cache(key, value)
      @cache[caller[0][/`.*'/][1..-2]] ||= {}
      @cache[caller[0][/`.*'/][1..-2]][key] = value
    end

    def print_cache
      ap @cache
    end

    # @return:
    # {
    #   client: self,
    #   pair_name: e.g. "ETH-BTC",
    #   price: price in order book,
    #   exchange_rate: will be inversed number if different direction,
    #   method: direction[:reversed] ? :sell : :buy,
    #   stock: the remaining stock size,
    # }
    def orderbook_price(source, dest, refresh: false)
      raise NotImplementedError
    end

    def available_balance(coin, refresh: false)
      raise NotImplementedError
    end

    def place_order!(pair_name, method, price, size)
      raise NotImplementedError
    end

    def to_s
      self.class.name
    end

    def inspect
      "#{to_s}.instance"
    end
  end
end
