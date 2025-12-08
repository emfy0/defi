class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(create_user_params.merge(mnemonic: CoinCrypto::Mnemonic.generate))

    if @user.save
      start_new_session_for @user
      redirect_to root_url
    else
      redirect_to new_session_path, alert: "Попробуйте другой username или пароль"
    end
  end

  def show
  end

  private

  def create_user_params = params.require(:user).permit(:username, :password)
end
