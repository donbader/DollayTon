module Trading
  class Bot
    STRATEGIES_PATH = "#{Rails.root}/lib/trading/strategy/*"

    attr_reader :current_strategy, :available_strategies

    def self.test
      new({strategy: "no_brain"})
    end

    def initialize(config)
      @config = config
      reload_strategies
      @current_strategy = @available_strategies.find { |s| s.alias == config[:strategy] }
    end

    def run
      puts @current_strategy.alias
      puts @current_strategy.description
    end

    def set_config
      yield(@config)
    end

    def reload_strategies
      Dir[STRATEGIES_PATH].each { |path| load path }
      @available_strategies = Strategy::Base.descendants
    end
  end
end
