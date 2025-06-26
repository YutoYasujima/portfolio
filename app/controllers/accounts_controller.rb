class AccountsController < ApplicationController
  def index
    @user = current_user
    @profile = current_user.profile
    @address = current_user.profile.prefecture.name_kanji + current_user.profile.municipality.name_kanji
    geocoding = Geocoder.search(@address).first.coordinates
    @machi_repo = MachiRepo.new(latitude: geocoding[0], longitude: geocoding[1])
  end

  def destroy
    user = current_user
    sign_out user
    reset_session
    user.destroy!

    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, notice: "ユーザーを削除しました" }
      format.json { head :no_content }
    end
  end
end
