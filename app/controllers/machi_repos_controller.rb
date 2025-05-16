class MachiReposController < ApplicationController
  before_action :set_machi_repo, only: %i[ show ]

  def index
  end

  def show
  end

  def new
    @address = current_user.profile.prefecture.name_kanji + current_user.profile.municipality.name_kanji
    geocoding = Geocoder.search(@address).first.coordinates
    @machi_repo = MachiRepo.new(latitude: geocoding[0], longitude: geocoding[1])
  end

  def create
    @machi_repo = current_user.machi_repos.build(machi_repo_params)
    if @machi_repo.save
      redirect_to @machi_repo, notice: "User was successfully created."
    else
      flash.now[:alert] = "失敗"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_machi_repo
    @machi_repo = MachiRepo.find(params[:id])
  end

  def machi_repo_params
    params.require(:machi_repo).permit(:title, :info_level, :category, :description, :hotspot_settings, :hotspot_area_radius, :latitude, :longitude, :image, :image_cache, :tag_names)
  end
end
