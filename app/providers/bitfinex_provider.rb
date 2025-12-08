require 'net/http'

module BitfinexProvider
  extend self

  BITFINEX_EXCHANGE_RATE_URL = URI('https://api.bitfinex.com/v2/calc/fx').freeze

  class UnknownCurrency < StandardError; end

  def exchange_rate_of(cur, to_cur)
    res = Net::HTTP.post(
      BITFINEX_EXCHANGE_RATE_URL,
      { ccy1: cur, ccy2: to_cur }.to_json,
      'Content-Type' => 'application/json'
    )

    raise UnknownCurrency unless res.is_a?(Net::HTTPSuccess)

    res.body[1..-2].to_d
  end
end
