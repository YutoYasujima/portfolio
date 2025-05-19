class MachiReposController < ApplicationController
  before_action :set_machi_repo, only: %i[ show ]

  def index
    # Googleマップにマイタウンを表示するための情報取得
    @address = current_user.mytown_address
    geocoding = Geocoder.search(@address).first.coordinates
    @latitude = geocoding[0]
    @longitude = geocoding[1]
    # 半径1km圏内のデータ取得
    @near_hotspots = MachiRepo.near([ geocoding[0], geocoding[1] ], 1)
    # マイタウンのまちレポ
    @machi_repos = MachiRepo.where(address: @address).includes(:tags, user: :profile).order(created_at: :desc)
  end

  def show
  end

  def new
    # Googleマップにマイタウンを表示するための情報取得
    address = current_user.mytown_address
    geocoding = Geocoder.search(address).first.coordinates
    @machi_repo = MachiRepo.new(address: address, latitude: geocoding[0], longitude: geocoding[1])
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

  # ホーム画面のまちレポ表示
  def fetch_machi_repos
    if params[:address].present?
      # 住所検索文字によるジオコーディング
      results = Geocoder.search(params[:address])
    elsif params[:latitude].present? && params[:longitude].present?
      # 現在地 or マーカーの座標によるリバースジオコーディング
      results = Geocoder.search([ params[:latitude], params[:longitude] ])
    else
      # マイタウンによるジオコーディング
      results = Geocoder.search(current_user.mytown_address)
    end

    result = results.first
    @address = result.state + result.city
    @latitude = params[:latitude] || result.coordinates[0]
    @longitude = params[:longitude] || result.coordinates[1]

    # 半径1km圏内のまちレポ取得
    @near_hotspots = MachiRepo.near([ @latitude, @longitude ], 1)
    # "まち"のまちレポ取得
    @machi_repos = MachiRepo.where(address: @address).includes(:tags, user: :profile).order(created_at: :desc)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_machi_repo
    @machi_repo = MachiRepo.find(params[:id])
  end

  def machi_repo_params
    params.require(:machi_repo).permit(:title, :info_level, :category, :description, :hotspot_settings, :hotspot_area_radius, :address, :latitude, :longitude, :image, :image_cache, :tag_names)
  end
end
