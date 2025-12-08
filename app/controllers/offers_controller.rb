class OffersController < ApplicationController
  def new
    @offer = Offer.new
  end

  def create
    @offer = Current.user.offers.new(offer_params)

    if @offer.save
      redirect_to offers_url, notice: "Оффер успешно создан."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @offers = Offer.where.not(user: Current.user)
  end

  def show = @offer = Offer.find_by!(id: params[:id])

  private

  def offer_params
    params
      .require(:offer)
      .permit(:payment_method, :value, :ltv_percent, :interest_percent)
  end
end
