
require "cobinhood_api"
require "awesome_print"
require "pry"
require "yaml"
require "bigdecimal"
require "bigdecimal/util"
require_relative "./api"

class Robot
  attr_reader :balances
  SECRETS = YAML.load_file("../../secrets.yml")
  API = Api.new('Cobinhood')

  PAIRS = [
    "ETH-USDT",
    "BTC-USDT",
    "ETH-BTC",
  ]

  TRADING_TYPE = {
    sell: TRADING_ORDER_SIDE::SIDE_ASK,
    buy: TRADING_ORDER_SIDE::SIDE_BID,
  }

  def initialize(base, coin1, coin2)
    @balances = {}
    @base = base
    @coin1 = coin1
    @coin2 = coin2
  end
  # USDT -> ETH -> BTC -> USDT
  # @return:
  #   max_input
  #   profit_rate
  def calculate_triangle(fund)
    refresh_balances(@base, @coin1, @coin2)
    print_balances

    pairs = [
      find_pair(@coin1, base: @base),
      find_pair(@coin2, base: @coin1),
      find_pair(@base, base: @coin2),
    ]

    points = pairs.map do |pair|
      [pair, API.get_market_order_book(pair[:name], 1)]
    end
    # ap points

    result1 = { order: [] }
    result2 = { order: [] }

    fund1 = fund
    result1[:order] << calculate_after_exchange(fund1, *points[0], method: :buy)
    fund1 = result1[:order].last[:exchanged_fund]
    result1[:order] << calculate_after_exchange(fund1, *points[1], method: :buy)
    fund1 = result1[:order].last[:exchanged_fund]
    result1[:order] << calculate_after_exchange(fund1, *points[2], method: :buy)
    fund1 = result1[:order].last[:exchanged_fund]

    fund2 = fund
    result2[:order] << calculate_after_exchange(fund2, *points[2], method: :sell)
    fund2 = result2[:order].last[:exchanged_fund]
    result2[:order] << calculate_after_exchange(fund2, *points[1], method: :sell)
    fund2 = result2[:order].last[:exchanged_fund]
    result2[:order] << calculate_after_exchange(fund2, *points[0], method: :sell)
    fund2 = result2[:order].last[:exchanged_fund]

    if fund1 > fund2
      result1.merge(earn: "#{fund1 - fund} #{@base}")
    else
      result2.merge(earn: "#{fund2 - fund} #{@base}")
    end
  end


  # @params:
  #   coin, base
  # @return:
  #   name: pair_name, reversed: true / false
  # @example:
  #   find_pair("ETH", base: "USDT") => {name: "ETH-USDT", reversed: false}
  def find_pair(coin, base: "USDT")
    name = PAIRS.find { |p| p == "#{coin}-#{base}" }
    return {name: name, reversed: false} if name

    name = PAIRS.find { |p| p == "#{base}-#{coin}" }
    return {name: name, reversed: true} if name

    raise "No such pair for #{coin}-#{base}"
  end

  def calculate_after_exchange(fund, pair, api_response, method:)
    opposite_method = method == :buy ? :sell : :buy
    method = pair[:reversed] ? opposite_method : method

    operator = method == :buy ? :/ : :*
    # price = method == :buy ? api_response[:asks][0]["price"] : api_response[:bids][0]["price"]
    price = (api_response[:asks][0]["price"] + api_response[:bids][0]["price"]).to_f / 2
    market_price = method == :buy ? api_response[:asks][0]["price"] : api_response[:bids][0]["price"]

    exchanged_fund = fund.send(operator, price)
    size = method == :buy ? exchanged_fund : exchanged_fund / price
    {
      pair_name: pair[:name],
      size: size,
      exchanged_fund: exchanged_fund,
      price: price,
      method: method,
      market_price: market_price,
    }
  end

  def place_order(pair_name, size, price, method:, type: "limit")
    puts [pair_name, TRADING_TYPE[method], type, size, price].inspect
    order = 123

    while order.nil?
      order = API.place_order(pair_name, TRADING_TYPE[method], type, size, price)
      sleep(0.3)
      # order=1
      break unless order.nil?
      puts "failed try again"
    end
    puts 'success'
  end

  # test(result[0], result[1]["USDT -> ETH -> BTC -> USDT"], result[2]["USDT -> BTC -> ETH -> USDT"])
  def test(points, r1, r2)
    points = points.map do |pair, response|
      [response[:asks][0]["price"], response[:bids][0]["price"]]
    end.flatten

    puts "UEBU correct" if r1 == 1000 / points[0] * points[3] * points[5]
    puts "UBEU correct" if r2 == 1000 / points[4] / points[2] * points[1]
  end

  def refresh_balances(*coins)
    coins.each { |coin| balances[coin] = API.get_available_balance(coin) }
  end

  def print_balances
    puts "Your balances:"
    balances.each { |k, v| puts "\t#{v} #{k}" }
  end

  def auto_trade(fund)
    ap result = calculate_triangle(fund)

    result[:order].each do |pair_name:, size:, price:, method:, **args|
      place_order(pair_name, size, price, method: method)
    end
  end
end