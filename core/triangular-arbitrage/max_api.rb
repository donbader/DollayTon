class MaxApi
  def initialize(api_key)
    @api_key = api_key
  end

  # DOMAIN: https://max-api.maicoin.com
  # Document file: https://max.maicoin.com/documents/api_v2

  # get_market_order_book
  # GET /api/v2/order_book
  #
  # params: {
  #   market: "ethusdt"
  #   asks_limit: 1
  #   bids_limit: 1
  # }
  #
  # response: {
  #   "asks": [
  #     {
  #       "side": "buy",
  #       "ord_type": "limit",
  #       "price": "21499.0",
  #       "state": "done",
  #       "market": "ethtwd",
  #       "volume": "0.2658",
  #     }
  #   ],
  #   "bids": [
  #     {...
  #     }
  #   ]
  # }



  # place_order
  # POST /api/v2/orders
  #
  # header: {
  #   X-MAX-ACCESSKEY: "",
  #   X-MAX-PAYLOAD: "",
  #   X-MAX-SIGNATURE: "",
  # }
  #
  # params: {
  #   market: "ethusdt",
  #   side: "sell",
  #   volumn: "1.23",
  #   price: "1.23",
  #   ord_type: "market",
  # }
  #
  # response: {
  #   state: "done"
  #   created_at: 1521726960,
  # }



  # get_available_balance
  # Get /api/v2/members/me
  #
  # header: {
  #   X-MAX-ACCESSKEY: "",
  #   X-MAX-PAYLOAD: "",
  #   X-MAX-SIGNATURE: "",
  # }
  #
  # response: {
  #   "accounts": [
  #     {
  #       "currency": "twd",
  #       "balance": "100000.0",
  #       "locked": "5566.0"
  #     }
  #   ],
  # }

end