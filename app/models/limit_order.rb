class LimitOrder < Order
  has_one :stop_loss_order, foreign_key: :parent_order_id, class_name: 'StopLossOrder'

  def self.create_with_stop_loss!(stop_loss_price, **args)
    direction = args[:direction]
    reversed_direction = direction.is_a?(String) ? !directions[direction] : !direction
    transaction do
      limit_order = create!(**args)
      limit_order.create_stop_loss_order!(
        pair_name: args[:pair_name],
        price: stop_loss_price,
        quantity: args[:quantity],
        direction: reversed_direction,
      )

      limit_order
    end
  end
end
