# used for stop limit
class StopLossOrder < Order
  belongs_to :parent_order, class_name: 'Order'
end
