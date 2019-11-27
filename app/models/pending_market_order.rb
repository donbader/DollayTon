# used for stop limit
class PendingMarketOrder < Order
  belongs_to :parent, class_name: 'Order'
end
