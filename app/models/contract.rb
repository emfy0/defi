class Contract < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :lender,   class_name: "User"
  belongs_to :borrower, class_name: "User"

  scope :for_user, ->(user) {
    [
      where(lender: user),
      where(borrower: user)
    ].reduce(&:or)
  }

  enum :state, %w[
    awaiting_deposit
    awaiting_payment
    in_progress
    completed
  ].index_with(&:itself)

  STATE_TRANSLATIONS = {
    "awaiting_deposit" => "Ожидание депозита",
    "awaiting_payment" => "Ожидание платежа",
    "in_progress" => "Aктивен",
    "completed" => "Завершен"
  }

  after_update_commit do
    broadcast_update_to self, target: dom_id(self), partial: "contracts/contract", locals: { contract: self }
  end

  def current_rate = BitfinexProvider.exchange_rate_of("BTC", currency)
  def current_escrow_volume = MempoolProvider.address_balance_sat(escrow.address).to_d / 10**8
  def current_escrow_value = (current_escrow_volume * current_rate).round(2)
  def current_ltv = (contract.value + contract.interest_value) / (current_escrow_volume * current_rate)

  def plafrom_private_key_hex
    plafrom_private_key.private_key_hex
  end

  def plafrom_public_key_hex
    plafrom_private_key.public_key_hex
  end

  def akh_public_key_hex
    xpub = CoinCrypto::ExtendedPublicKey.from_base58(
      Rails.application.credentials[:akh_public_key]
    )

    xpub.derive(id.to_s).public_key_hex
  end

  def escrow
    CoinCrypto::Escrow.create(
      blockchain_network: :btc_testnet,
      kind: :p2wsh,
      m: 3,
      public_keys: [
        lender_public_key_hex,
        borrower_public_key_hex,
        plafrom_public_key_hex,
        akh_public_key_hex
      ]
    )
  end

  def escrow_withdrawal_transaction
    utxos = MempoolProvider.utxos_for_address(escrow.address).map do |utxo|
      {
        hash: utxo["txid"],
        output_index: utxo["vout"],
        amount: utxo["value"]
      }
    end

    dust_limit = 512

    withdrawal_volume = (utxos.sum { it[:amount] } - dust_limit)

    CoinCrypto::EscrowWithdrawalTransaction.from_escrow(
      escrow: escrow,
      recipients: [[refund_address, withdrawal_volume]],
      utxos:
    )
  end

  def user_role(user)
    case user.id
    in ^(lender_id)
      :lender
    in ^(borrower_id)
      :borrower
    end
  end

  private

  def plafrom_private_key
    xpriv = CoinCrypto::ExtendedPrivateKey.from_base58(
      Rails.application.credentials[:platfrom_private_key]
    )

    xpriv.derive(id.to_s)
  end
end
