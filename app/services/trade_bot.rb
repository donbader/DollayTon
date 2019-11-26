class TradeBot
  attr_reader :env
  def initialize
    @env = {
      end_time: 1.day.from_now,
    }
    @websocket_machine = Binance::Client::WebsocketMachine.new
  end

  def stop
    @websocket_machine.stop
  end

  def run
    env[:start_time] = Time.now

    @websocket_machine.run do |event|
      env[:current_data] = JSON event.data

      @websocket_machine.stop if Time.now >= env[:end_time]
    end

    self
  end

  def current_data
    env[:current_data]
  end
end
