class LimitOrder < Order
  has_one :pending_market_order, foreign_key: :parent_id, class_name: 'PendingMarketOrder'
end
