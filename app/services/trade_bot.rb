# @example
#   bot = TradeBot.new
#   bot.perform(CoreyStrategy)
#   bot.stop
class TradeBot
  include Singleton

  SETTINGS = YAML.load_file(Rails.root.join("setting.yml"))[Rails.env]

  attr_reader :env, :websocket_machine, :processing_machine

  def initialize
    @env = {
      end_time: 1.day.from_now,
      current_strategy: CoreyStrategy,
      batch: Batch::CoreyBatch.new,
      completed_batches: [],
      current_price_data: nil,
      running: false,
    }

    @websocket_url = SETTINGS["websocket_url"]
  end

  def run
    return if running?

    start_updating_price
    start_processing_order

    env[:running] = true

    self
  end

  def stop
    env[:running] = false
    @processing_machine.exit
    @websocket_machine.stop
  end

  def start_updating_price
    return if running?

    env[:start_time] = Time.now

    @websocket_machine = Binance::Client::WebsocketMachine.new(@websocket_url)
    @websocket_machine.run do |event|
      env[:current_price_data] = JSON event.data

      @websocket_machine.stop if Time.now >= env[:end_time]
    end

    @websocket_machine
  end

  def start_processing_order
    return if running?

    @processing_machine = Thread.new do
      while running?
        perform
        sleep(0.2.seconds)
      end
    end
  end

  def current_price_data
    env[:current_price_data]
  end

  def current_strategy
    env[:current_strategy]
  end

  def batch
    env[:batch]
  end

  def completed_batches
    env[:completed_batches]
  end

  def running?
    env[:running]
  end

  def perform
    return unless current_price_data.present?
    current_strategy.new(current_price_data, self).perform
  rescue => e
    binding.pry
    123
  end
end
