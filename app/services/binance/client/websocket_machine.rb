module Binance
  module Client
    class WebsocketMachine
      def client
        @websocket ||= Binance::Client::Websocket.new
      end

      def stop
        @websocket_thread.exit
      end

      def run
        @websocket_thread ||= Thread.new do
          EM.run do
            # Listen to all interested coins
            client.partial_book_depth(
              symbol: "BTCUSDT",
              level: "5",
              methods: {
                open: proc { puts 'connected' },
                close: proc { puts 'stop liao' },
                error: proc { |e| puts e },
                message: proc { |e| yield(e) },
              }
            )
          end
        end
      end
    end
  end
end
