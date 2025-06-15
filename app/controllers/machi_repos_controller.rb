class MachiReposController < ApplicationController
  before_action :set_mytown_location, only: %i[ new edit ]

  MACHI_REPO_PER_PAGE = 12

  def index
    raw_search_params = {}
    # 前回の表示結果があれば取得する
    if session[:machi_repos_home_display_status].present?
      raw_search_params = session[:machi_repos_home_display_status]
      raw_search_params["address"] = nil
    end

    # 表示用データを取得する
    prepare_search_data(raw_search_params)
    respond_to do |format|
      format.html
    end
  end

  def search
    # 表示用データを取得する
    prepare_search_data(search_params)
    respond_to do |format|
      format.turbo_stream
    end
  end

  # "まち"のまちレポ無限スクロールデータ取得
  def load_more
    # まちレポ全体表示時のスナップショット取得
    snapshot_time = Time.at(session[:machi_repos_snapshot_time].to_i)
    cursor_updated_at = Time.at(params[:previous_last_updated].to_i)
    cursor_id = params[:previous_last_id].to_i

    form_params = enrich_search_params_with_coordinates(search_params)

    @search_form = MachiRepoSearchForm.new(form_params)
    search_result = @search_form.search_machi_repos.where("machi_repos.updated_at <= ?", snapshot_time)

    # データの総数を取得する
    @machi_repos_count = search_result.size

    # 最終ページ判定のため1件多く取得
    raw_machi_repos = search_result
                      .where("machi_repos.updated_at < ? OR (machi_repos.updated_at = ? AND id < ?)", cursor_updated_at, cursor_updated_at, cursor_id)
                      .order("machi_repos.updated_at DESC, machi_repos.id DESC")
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

    # ログイン済み & 投稿者本人でなければ、views_countをインクリメント
    if user_signed_in? && current_user.id != @machi_repo.user_id
      track_view_count(@machi_repo.id)
      # インクリメントされたviews_countを取得
      @machi_repo.reload
    end
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

  def prepare_search_data(raw_search_params)
    # 無限スクロール対策のため、UNIXタイムスタンプで保存
    @snapshot_time = Time.current
    session[:machi_repos_snapshot_time] = @snapshot_time.to_i

    # 検索用ストロングパラメータに値を追加
    form_params = enrich_search_params_with_coordinates(raw_search_params)

    # sessionに画面表示の条件を保持しておく
    session[:machi_repos_home_display_status] = form_params.to_h

    @search_form = MachiRepoSearchForm.new(form_params)

    unless @search_form.valid?
      flash.now[:alert] = [ "検索条件を確認してください" ] + @search_form.errors.full_messages
    end

    # 周辺のホットスポット取得
    @near_hotspots = @search_form.search_near_hotspots.order("machi_repos.updated_at DESC, machi_repos.id DESC")

    # "まち"のまちレポ取得
    search_result = @search_form.search_machi_repos.where("machi_repos.updated_at <= ?", @snapshot_time)
    # データ総数取得
    @machi_repos_count = search_result.size
    # 無限スクロール前のデータ取得
    @machi_repos = search_result.order("machi_repos.updated_at DESC, machi_repos.id DESC").limit(MACHI_REPO_PER_PAGE)
    # 最終ページのデータか判定(初期表示のため下記でOK)
    @is_last_page = @machi_repos_count <= MACHI_REPO_PER_PAGE
  end

  # search_paramsにマップ情報を追加する
  def enrich_search_params_with_coordinates(raw_search_params)
    form_params = raw_search_params

    results =
      if form_params["address"].present?
        Geocoder.search(form_params["address"])
      elsif form_params["latitude"].present? && form_params["longitude"].present?
        Geocoder.search([ form_params["latitude"], form_params["longitude"] ])
      else
        Geocoder.search(current_user.mytown_address)
      end

    result = results.first
    @address = result.state + result.city
    @latitude = form_params["latitude"].presence || result.coordinates[0]
    @longitude = form_params["longitude"].presence || result.coordinates[1]

    form_params["address"] = @address
    form_params["latitude"] = @latitude
    form_params["longitude"] = @longitude

    form_params
  end

  # エラーメッセージを追加する
  def append_errors_to_flash(record, action_name)
    flash.now[:alert] = [ "まちレポの#{action_name}に失敗しました" ]
    flash.now[:alert] += record.errors.full_messages if record.errors.any?
  end

  # マイタウン情報を設定する
  def set_mytown_location
    @mytown_address = current_user.mytown_address
    geocoding = Geocoder.search(@mytown_address).first.coordinates
    @mytown_latitude = geocoding[0]
    @mytown_longitude = geocoding[1]
  end

  # まちレポ詳細の閲覧数登録処理
  def track_view_count(machi_repo_id)
    cookie_key = "viewed_machi_repo_#{machi_repo_id}"

    # 短時間に同じユーザーの閲覧で何度もインクリメントされないようにする
    unless cookies[cookie_key]
      MachiRepo.increment_counter(:views_count, machi_repo_id)
      # 有効期限を24時間に設定
      cookies[cookie_key] = { value: true, expires: 24.hours.from_now }
    end
  end

  # DB登録時のストロングパラメータ取得
  def machi_repo_params
    params.require(:machi_repo).permit(
      :title, :info_level, :category, :description,
      :hotspot_settings, :hotspot_area_radius,
      :address, :latitude, :longitude,
      :image, :image_cache, :tag_names
    )
  end

  # 検索時のストロングパラメータ取得
  def search_params
    params.fetch(:search, {}).permit(
      :title, :info_level, :category, :tag_names, :tag_match_type,
      :display_range_radius, :display_hotspot_count,
      :start_date, :end_date, :latitude, :longitude, :address
    )
  end
end
