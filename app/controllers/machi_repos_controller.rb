class MachiReposController < ApplicationController
  before_action :set_mytown_location, only: %i[new edit]

  MACHI_REPO_PER_PAGE = 12

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

  # "まち"のまちレポ無限スクロールデータ取得
  def load_more
    # まちレポ全体表示時のスナップショット取得
    snapshot_time = Time.at(session[:records_snapshot_time].to_i)
    cursor_updated_at = Time.at(params[:previous_last_updated].to_i)
    cursor_id = params[:previous_last_id].to_i

    form_params = enrich_search_params_with_coordinates(search_params)

    @search_form = MachiRepoSearchForm.new(form_params)
    search_result = @search_form.search_machi_repos.where("updated_at <= ?", snapshot_time)

    # データの総数を取得する
    @machi_repos_count = search_result.size

    # 最終ページ判定のため1件多く取得
    raw_machi_repos = search_result
                      .where("updated_at < ? OR (updated_at = ? AND id < ?)", cursor_updated_at, cursor_updated_at, cursor_id)
                      .order(updated_at: :desc, id: :desc)
                      .limit(MACHI_REPO_PER_PAGE + 1)
    # 最終ページ判定
    @is_last_page = raw_machi_repos.size <= MACHI_REPO_PER_PAGE

    # 表示分切り出し
    @machi_repos = raw_machi_repos.first(MACHI_REPO_PER_PAGE)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def show
    @machi_repo = MachiRepo.includes(user: :profile).find(params[:id])
  end

  def new
    @machi_repo = MachiRepo.new(
      address: @mytown_address,
      latitude: @mytown_latitude,
      longitude: @mytown_longitude
    )
  end

  def create
    @machi_repo = current_user.machi_repos.build(machi_repo_params)
    if @machi_repo.save
      redirect_to @machi_repo, notice: "まちレポを作成しました"
    else
      append_errors_to_flash(@machi_repo, "作成")
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
      append_errors_to_flash(@machi_repo, "更新")
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
    # 無限スクロール対策のため、UNIXタイムスタンプで保存
    snapshot_time = Time.current
    session[:records_snapshot_time] = snapshot_time.to_i

    form_params = enrich_search_params_with_coordinates(search_params)

    @search_form = MachiRepoSearchForm.new(form_params)

    unless @search_form.valid?
      flash.now[:alert] = [ "検索条件を確認してください" ] + @search_form.errors.full_messages
    end

    # 周辺のホットスポット取得
    @near_hotspots = @search_form.search_near_hotspots.order(updated_at: :desc, id: :desc)

    # "まち"のまちレポ取得
    search_result = @search_form.search_machi_repos.where("updated_at <= ?", snapshot_time)
    # データ総数取得
    @machi_repos_count = search_result.size
    # 無限スクロール前のデータ取得
    @machi_repos = search_result.order(updated_at: :desc, id: :desc).limit(MACHI_REPO_PER_PAGE)
    # 最終ページのデータか判定
    @is_last_page = @machi_repos_count <= MACHI_REPO_PER_PAGE
  end

  def enrich_search_params_with_coordinates(search_params)
    form_params = search_params

    results =
      if form_params[:address].present?
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

    form_params
  end

  def append_errors_to_flash(record, action_name)
    flash.now[:alert] = [ "まちレポの#{action_name}に失敗しました" ]
    flash.now[:alert] += record.errors.full_messages if record.errors.any?
  end

  def set_mytown_location
    @mytown_address = current_user.mytown_address
    geocoding = Geocoder.search(@mytown_address).first.coordinates
    @mytown_latitude = geocoding[0]
    @mytown_longitude = geocoding[1]
  end

  def machi_repo_params
    params.require(:machi_repo).permit(
      :title, :info_level, :category, :description,
      :hotspot_settings, :hotspot_area_radius,
      :address, :latitude, :longitude,
      :image, :image_cache, :tag_names
    )
  end

  def search_params
    params.fetch(:search, {}).permit(
      :title, :info_level, :category, :tag_names, :tag_match_type,
      :display_range_radius, :display_hotspot_count,
      :start_date, :end_date, :latitude, :longitude, :address
    )
  end
end
