class MachiReposController < ApplicationController
  def index
    prepare_search_data
    respond_to do |format|
      format.html
    end
  end

  def search
    prepare_search_data
    respond_to do |format|
      format.turbo_stream
    end
  end

  def show
    @machi_repo = MachiRepo.includes(user: :profile).find(params[:id])
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
      redirect_to @machi_repo, notice: "まちレポを作成しました"
    else
      flash.now[:alert] = [ "まちレポの作成に失敗しました" ]
      if @machi_repo.errors.any?
        flash.now[:alert] += @machi_repo.errors.full_messages
      end
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @machi_repo = current_user.machi_repos.includes(user: :profile).find(params[:id])
  end

  def update
    @machi_repo = current_user.machi_repos.find(params[:id])
    if @machi_repo.update(machi_repo_params)
      redirect_to machi_repo_path(@machi_repo), notice: "まちレポを更新しました"
    else
      flash.now[:alert] = [ "まちレポの更新に失敗しました" ]
      if @machi_repo.errors.any?
        flash.now[:alert] += @machi_repo.errors.full_messages
      end
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    machi_repo = current_user.machi_repos.find(params[:id])
    machi_repo.destroy!
    redirect_to machi_repos_path, notice: "まちレポを削除しました", status: :see_other
  end

  private

  def prepare_search_data
    form_params = search_params

    results = if form_params[:address].present?
      Geocoder.search(form_params[:address])
    elsif form_params[:latitude].present? && form_params[:longitude].present?
      Geocoder.search([ form_params[:latitude], form_params[:longitude] ])
    else
      Geocoder.search(current_user.mytown_address)
    end

    result = results.first
    @address = result.state + result.city
    @latitude = form_params[:latitude].presence || result.coordinates[0]
    @longitude = form_params[:longitude].presence || result.coordinates[1]

    form_params[:address] = @address
    form_params[:latitude] = @latitude
    form_params[:longitude] = @longitude

    @search_form = MachiRepoSearchForm.new(form_params)

    unless @search_form.valid?
      flash.now[:alert] = [ "検索条件を確認してください" ]
      flash.now[:alert] += @search_form.errors.full_messages
    end

    @near_hotspots = @search_form.search_near_hotspots

    search_result = @search_form.search_machi_repos
    @machi_repos_count = search_result.length
    @machi_repos = search_result.page(params[:page])
  end

  def machi_repo_params
    params.require(:machi_repo).permit(:title, :info_level, :category, :description, :hotspot_settings, :hotspot_area_radius, :address, :latitude, :longitude, :image, :image_cache, :tag_names)
  end

  def search_params
    params.fetch(:search, {}).permit(:title, :info_level, :category, :tag_names, :tag_match_type, :display_range_radius, :display_hotspot_count, :start_date, :end_date, :latitude, :longitude, :address)
  end
end
