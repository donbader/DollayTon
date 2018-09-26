module TriangleArbitrage
  module Strategy
    class Base
      def initialize(base, coin1, coin2)
        @base = base
        @coin1 = coin1
        @coin2 = coin2

        @clients = [
          Client::Cobinhood.baimao,
          Client::Max.baimao,
          # Client::Binance.instance,
        ]
      end

      # @returns: <Hash>
      # {
      #   orders: [
      #     {
      #       client:
      #       pair_name: for client args to place order
      #       price:     for client args to place order
      #       method:    for client args to place order
      #       size:      for client args to place order
      #     } * 3
      #   ]
      #   exchanged_percentage: after exchanging, the money will be how many times
      #   max_invest_amount: max invest amount
      #   invested_fund: invested fund
      #   profit: profit calculated by invested fund
      # }
      def calculate(*_args, **_kwargs, &_block)
        raise NotImplementedError
      end
    end
  end
end
