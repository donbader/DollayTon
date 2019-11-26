# @example
#   bot = TradeBot.new
#   bot.perform(CoreyStrategy)
#   bot.stop
class TradeBot
  attr_reader :env
  def initialize
    @env = {
      end_time: 1.day.from_now,
    }
    @websocket_machine = Binance::Client::WebsocketMachine.new
    start_updating_price
  end

  def stop
    @websocket_machine.stop
  end

  def start_updating_price
    env[:start_time] = Time.now

    @websocket_machine.run do |event|
      env[:current_price_data] = JSON event.data

      @websocket_machine.stop if Time.now >= env[:end_time]
    end

    self
  end

  def current_price_data
    env[:current_price_data]
  end

  def perform(strategy)
    strategy.perform(current_price_data)
  end
end
