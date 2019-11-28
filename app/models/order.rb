class Order < ApplicationRecord
  attribute :status, default: 'waiting'

  enum direction: { bid: true, ask: false }
  enum status: {
    waiting: 'waiting',
    completed: 'completed',
    cancelled: 'cancelled',
  }

  def self.destroy_all
    all.reverse.each(&:destroy)
    true
  end

  before_save do
    if status_changed?
      ap "[#{self.class}] #{self.direction} > status_changed? to #{self.status}----------"
    end
  end
end
