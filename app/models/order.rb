class Order < ApplicationRecord
  enum direction: { right_to_left: true, left_to_right: false }
end
