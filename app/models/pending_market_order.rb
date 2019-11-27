# used for stop limit
class PendingMarketOrder < Order
  belongs_to :parent_order, class_name: 'Order'
end
