class ContractsController < ApplicationController
  def new
    @offer = Offer.find(params[:offer_id])
    @contract = Contract.new
  end

  def create
    @offer = Offer.find(params[:offer_id])

    @contract = Contract.new(contract_params)

    @contract.state = "awaiting_deposit"
    @contract.currency = "USD"

    @contract.lender = @offer.user
    @contract.borrower = Current.user

    @contract.payment_method     = @offer.payment_method
    @contract.value              = @offer.value
    @contract.interest_value     = (@offer.value * @offer.interest_percent / 100.to_d).round(2)
    @contract.ltv_percent        = @offer.ltv_percent
    @contract.interest_percent   = @offer.interest_percent

    @contract.initial_depopsit_volume =
      (@contract.value + @contract.interest_value) /
      (@contract.current_rate * @contract.ltv_percent / 100.to_d)
    @contract.initial_depopsit_volume = @contract.initial_depopsit_volume.round(8)

    @contract.lender_public_key_hex = @contract.lender.public_key_hex
    @contract.borrower_public_key_hex = @contract.borrower.public_key_hex

    if @contract.save
      redirect_to @contract, notice: "Контракт создан."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @contract = Contract.for_user(Current.user).find_by!(id: params[:id])
  end

  def check_deposit
    @contract = Contract.for_user(Current.user).find_by!(id: params[:id])

    @contract.with_lock do
      return redirect_to @contract, notice: "Неверное состояние контракта" if @contract.state != "awaiting_deposit"

      if @contract.current_escrow_volume >= @contract.initial_depopsit_volume
        @contract.update!(state: "awaiting_payment")
      end
    end

    redirect_to @contract
  end

  def payment_paid
    @contract = Contract.for_user(Current.user).find_by!(id: params[:id])

    @contract.with_lock do
      return redirect_to @contract, notice: "Неверное состояние контракта" if @contract.state != "awaiting_payment"

      @contract.update!(state: "in_progress")
    end

    redirect_to @contract
  end

  def sign_release
    @contract = Contract.for_user(Current.user).find_by!(id: params[:id])

    @contract.with_lock do
      return redirect_to @contract, notice: "Неверное состояние контракта" if @contract.state != "in_progress"

      if @contract["psbt_#{@contract.user_role(Current.user)}_hex"].present?
        return redirect_to @contract, notice: "Контракт уже подписан"
      end

      ewtx = @contract.escrow_withdrawal_transaction
      ewtx.sign!(Current.user.private_key_hex)

      @contract.update!("psbt_#{@contract.user_role(Current.user)}_hex" => ewtx.to_psbt)

      signatures = %w[
        psbt_lender_hex
        psbt_borrower_hex
        psbt_akh_hex
      ]

      available_signatures = signatures.filter_map { @contract[it] }

      if available_signatures.size >= 2
        ewtx = @contract.escrow_withdrawal_transaction

        available_signatures.map { |psbt|
          CoinCrypto::EscrowWithdrawalTransaction.from_psbt(psbt, blockchain_network: :btc_testnet)
        }.each { |psbt| ewtx.combine!(psbt) }

        ewtx.sign!(@contract.plafrom_private_key_hex)

        @contract.update!(
          state: "completed",
          release_tx: ewtx.to_signed_tx
        )

        MempoolProvider.broadcast_transaction(@contract.release_tx)
      end
    end

    redirect_to @contract
  end

  private

  def contract_params
    params.require(:contract).permit(:repayment_method, :refund_address)
  end
end
