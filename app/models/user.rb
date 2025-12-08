class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :offers

  encrypts :mnemonic

  def xpriv = CoinCrypto::ExtendedPrivateKey.from_seed(
    CoinCrypto::Mnemonic.seed(mnemonic, ""),
    :btc_testnet
  )

  def public_key_hex = xpriv.public_key_hex
  def private_key_hex = xpriv.private_key_hex
end
