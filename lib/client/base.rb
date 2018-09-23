module Client
  class Base
    def initialize(*args, **kwargs)
      @cache = ActiveSupport::HashWithIndifferentAccess.new
    end

    def cache
      @cache[caller[0][/`.*'/][1..-2]] ||= {}
    end

    def print_cache
      ap @cache
    end

    # @return:
    # {
    #   pair_name: e.g. "ETH-BTC",
    #   price: price in order book,
    #   exchange_rate: will be inversed number if different direction,
    #   method: direction[:reversed] ? :sell : :buy,
    # }
    def order_book_price(source, dest, refresh: false)
      raise NotImplementedError
    end

    def available_balance(coin, refresh: false)
      raise NotImplementedError
    end
  end
end
