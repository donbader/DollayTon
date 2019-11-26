require 'faye/websocket'

# Public: Client with methods mirroring the Binance WebSocket API
module Binance
  module Client
    class Websocket
      attr_reader :base_url
      def initialize
        # exchanges url
        # @base_url = 'wss://stream.binance.com:9443'
        # futures url
        @base_url = 'wss://fstream.binance.com'
      end

      # Public: Create a single WebSocket stream
      #
      # :stream - The Hash used to define the stream
      #   :symbol   - The String symbol to listen to
      #   :type     - The String type of stream to listen to
      #   :level    - The String level to use for the depth stream (optional)
      #   :interval - The String interval to use for the kline stream (optional)
      #
      # :methods - The Hash which contains the event handler methods to pass to
      #            the WebSocket client
      #   :open    - The Proc called when a stream is opened (optional)
      #   :message - The Proc called when a stream receives a message
      #   :error   - The Proc called when a stream receives an error (optional)
      #   :close   - The Proc called when a stream is closed (optional)
      def ws_single(stream:, methods:)
        create_stream(
          "#{base_url}/ws/#{stream_url(stream)}",
          methods: methods,
        )
      end

      # Internal: Create a valid URL for a WebSocket to use
      #
      # :symbol - The String symbol to listen to
      # :type   - The String type the stream will listen to
      # :level    - The String level to use for the depth stream (optional)
      # :interval - The String interval to use for the kline stream (optional)
      def stream_url(symbol:, type:, level: '', interval: '')
        "#{symbol.downcase}@#{type}".tap do |url|
          url << level
          url << "_#{interval}" unless interval.empty?
        end
      end

      # Internal: Initialize and return a Faye::WebSocket::Client
      #
      # url - The String url that the WebSocket should try to connect to
      #
      # :methods - The Hash which contains the event handler methods to pass to
      #            the WebSocket client
      #   :open    - The Proc called when a stream is opened (optional)
      #   :message - The Proc called when a stream receives a message
      #   :error   - The Proc called when a stream receives an error (optional)
      #   :close   - The Proc called when a stream is closed (optional)
      private def create_stream(url, methods:)
        Faye::WebSocket::Client.new(url).tap do |websocket|
          methods.each_pair do |key, method|
            websocket.on(key) { |event| method.call(event) }
          end
        end
      end

      # =======================================================================
      # WebSocket APIs
      # =======================================================================
      def partial_book_depth(symbol:, level:, methods:)
        ws_single(
          stream: {
            symbol: symbol,
            type: 'depth',
            level: level,
          },
          methods: methods,
        )
      end
    end
  end
end
