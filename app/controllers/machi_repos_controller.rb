class MachiReposController < ApplicationController
  before_action :set_machi_repo, only: %i[ show ]

  def index
    form_params = search_params
    if form_params[:address].present?
      # 住所検索文字によるジオコーディング
      results = Geocoder.search(form_params[:address])
    elsif form_params[:latitude].present? && form_params[:longitude].present?
      # 現在地 or マーカー or 検索ボタンクリック時の座標によるリバースジオコーディング
      results = Geocoder.search([ form_params[:latitude], form_params[:longitude] ])
    else
      # マイタウンによるジオコーディング
      results = Geocoder.search(current_user.mytown_address)
    end

    result = results.first
    @address = result.state + result.city
    # Rubyでは空文字がtruthyのため条件演算子を使用
    @latitude = form_params[:latitude].present? ? form_params[:latitude] : result.coordinates[0]
    @longitude = form_params[:longitude].present? ?  form_params[:longitude] : result.coordinates[1]

    form_params[:address] = @address
    form_params[:latitude] = @latitude
    form_params[:longitude] = @longitude

    # まちレポ検索
    @search_form = MachiRepoSearchForm.new(form_params)

    # バリデーションエラーがあっても正常な項目で検索を実行
    if !@search_form.valid?
      flash.now[:alert] = @search_form.errors.full_messages
    end

    # マップのホットスポット取得
    @near_hotspots = @search_form.search_near_hotspots

    # "まち"のまちレポ取得
    search_machi_repos_result = @search_form.search_machi_repos
    @machi_repos_count = search_machi_repos_result.count
    @machi_repos = search_machi_repos_result.page(params[:page])

    respond_to do |format|
      format.turbo_stream
      format.html
    end
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

  private

  def set_machi_repo
    @machi_repo = MachiRepo.find(params[:id])
  end

  def machi_repo_params
    params.require(:machi_repo).permit(:title, :info_level, :category, :description, :hotspot_settings, :hotspot_area_radius, :address, :latitude, :longitude, :image, :image_cache, :tag_names)
  end

  def search_params
    params.fetch(:search, {}).permit(:title, :info_level, :category, :tag_names, :tag_match_type, :display_range_radius, :display_hotspot_count, :start_date, :end_date, :latitude, :longitude, :address)
  end
end
