require 'open-uri'
require 'net/http'

module MempoolProvider
  extend self

  MEMPOOL_API_URL = "https://mempool.space/signet/api/"

  def address_balance_sat(address)
    res = URI.open("#{MEMPOOL_API_URL}address/#{address}")
    addr_info = JSON.parse(res.read)
    chain_stats = addr_info['chain_stats']
    mempool_stats = addr_info['mempool_stats']

    chain_stats['funded_txo_sum'] - chain_stats['spent_txo_sum'] +
      mempool_stats['funded_txo_sum'] - mempool_stats['spent_txo_sum']
  end

  def broadcast_transaction(transaction)
    url = URI("#{MEMPOOL_API_URL}tx")
    Net::HTTP.post url, transaction
  end

  def utxos_for_address(address)
    res = URI.open("#{MEMPOOL_API_URL}address/#{address}/utxo")
    JSON.parse(res.read)
  end
end
