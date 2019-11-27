class Order < ApplicationRecord
  attribute :status, default: 'waiting'

  enum direction: { bid: true, ask: false }
  enum status: {
    waiting: 'waiting',
    completed: 'completed',
    cancelled: 'cancelled',
  }
end
