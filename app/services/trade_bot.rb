# frozen_string_literal: true

# @example
#   TradeBot.instance.run
#   TradeBot.instance.output!
#   TradeBot.instance.output!
class TradeBot
  include Singleton

  attr_reader :env, :websocket_machine, :processing_machine

  def initialize
    @env = {
      end_time: 1.day.from_now,
      current_strategy: CoreyStrategy,
      batch: Batch::CoreyBatch.new,
      completed_batches: [],
      current_price_data: nil,
      running: false,
      output: {},
      error: nil
    }
  end

  def run
    return if running?

    start_updating_price
    start_processing_order

    env[:running] = true
  end

  def stop
    env[:running] = false
    @processing_machine&.exit
    @websocket_machine&.stop
  end

  def start_updating_price
    return if running?

    env[:start_time] = Time.now

    @websocket_machine = Binance::Client::WebsocketMachine.new
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
        result = perform
        ap(result) if env[:output][:debugging]
        sleep(0.2.seconds)
      end
    rescue StandardError => e
      env[:error] = e
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

  def output!
    env[:output][:debugging] = !env[:output][:debugging]
  end

  def last_error
    env[:error]
  end

  def perform
    return unless current_price_data.present?

    current_strategy.new(current_price_data, self).perform
  end
end
