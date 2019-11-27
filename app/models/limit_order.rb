class LimitOrder < Order
  has_one :pending_market_order, foreign_key: :parent_order_id, class_name: 'PendingMarketOrder'

  def self.create_with_stop_loss!(stop_loss_price, **args)
    transaction do
      limit_order = create!(**args)
      limit_order.create_pending_market_order!(
        pair_name: limit_order.pair_name,
        price: stop_loss_price,
        quantity: limit_order.quantity,
        direction: !limit_order.direction,
      )
    end
  end
end
