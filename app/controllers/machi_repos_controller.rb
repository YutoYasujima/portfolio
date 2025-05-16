class MachiReposController < ApplicationController
  def index
  end

  def new
    @address = current_user.profile.prefecture.name_kanji + current_user.profile.municipality.name_kanji
    geocoding = Geocoder.search(@address).first.coordinates
    @machi_repo = MachiRepo.new(latitude: geocoding[0], longitude: geocoding[1])
  end

  def create
    # @user = User.new(user_params)
    # respond_to do |format|
    #   if @user.save
    #     format.html { redirect_to @user, notice: "User was successfully created." }
    #     format.json { render :show, status: :created, location: @user }
    #   else
    #     format.html { render :new, status: :unprocessable_entity }
    #     format.json { render json: @user.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  private

  def machi_repo_params
    params.require(:machi_repo).permit(:title, :info_level, :category, :description, :hotspot_settings, :hotspot_area_radius, :latitude, :longitude, :image, :image_cache, :tag_names)
  end
end
