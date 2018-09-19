
require "cobinhood_api"
require "awesome_print"
require "pry"


PAIRS = [
  "ETH-USDT",
  "BTC-USDT",
  "ETH-BTC",
]

TRADING_TYPE = {
  sell: :bids,
  buy: :asks,
}

API = CobinhoodApi.new

# USDT -> ETH -> BTC -> USDT
# @return:
#   max_input
#   profit_rate
def calculate_triangle(fund, base, coin1, coin2)
  pairs = [
    find_pair(coin1, base: base),
    find_pair(coin2, base: coin1),
    find_pair(base, base: coin2),
  ]

  points = pairs.map do |pair|
    [pair, API.get_market_order_book(pair[:name], 1)]
  end

  fund1 = fund
  fund1 = calculate_after_exchange(fund1, *points[0], method: :buy)[:exchanged_fund]
  fund1 = calculate_after_exchange(fund1, *points[1], method: :buy)[:exchanged_fund]
  fund1 = calculate_after_exchange(fund1, *points[2], method: :buy)[:exchanged_fund]

  fund2 = fund
  fund2 = calculate_after_exchange(fund2, *points[2], method: :sell)[:exchanged_fund]
  fund2 = calculate_after_exchange(fund2, *points[1], method: :sell)[:exchanged_fund]
  fund2 = calculate_after_exchange(fund2, *points[0], method: :sell)[:exchanged_fund]

  if fund1 > fund2
    puts fund1
    {
      earn: "#{fund1 - fund} #{base}",
      order: [
        calculate_after_exchange(fund1, *points[0], method: :buy).reject { |k, _| k == :exchanged_fund },
        calculate_after_exchange(fund1, *points[1], method: :buy).reject { |k, _| k == :exchanged_fund },
        calculate_after_exchange(fund1, *points[2], method: :buy).reject { |k, _| k == :exchanged_fund },
      ],
    }
  else
    puts fund2
    {
      earn: "#{fund2 - fund} #{base}",
      order: [
        calculate_after_exchange(fund2, *points[2], method: :sell).reject { |k, _| k == :exchanged_fund },
        calculate_after_exchange(fund2, *points[1], method: :sell).reject { |k, _| k == :exchanged_fund },
        calculate_after_exchange(fund2, *points[0], method: :sell).reject { |k, _| k == :exchanged_fund },
      ],
    }
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
  price = (api_response[:asks][0]["price"] + api_response[:bids][0]["price"]).to_f / 2

  {
    exchanged_fund: fund.send(operator, price),
    price: price,
    method: method,
  }
end

# test(result[0], result[1]["USDT -> ETH -> BTC -> USDT"], result[2]["USDT -> BTC -> ETH -> USDT"])
def test(points, r1, r2)
  points = points.map do |pair, response|
    [response[:asks][0]["price"], response[:bids][0]["price"]]
  end.flatten

  puts "UEBU correct" if r1 == 1000 / points[0] * points[3] * points[5]
  puts "UBEU correct" if r2 == 1000 / points[4] / points[2] * points[1]
end

# calculate_triangle
# 100.times {
  # sleep(0.5)
  # ap calculate_triangle("USDT", "ETH", "BTC")
# }
result = calculate_triangle(1000, "USDT", "ETH", "BTC")
ap result


# ask ask bids -> earn

# asks asks | asks

# bids bids | bids

# bids bids asks -> earn
