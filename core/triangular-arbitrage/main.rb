require_relative './robot'

# ==================================================================================
# MAIN
def main
  robot = Robot.new("USDT", "ETH", "BTC")
  robot.auto_trade(30)
end

main
