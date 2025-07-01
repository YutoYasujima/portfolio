class TutorialsController < ApplicationController
  before_action :set_mytown_location, only: %i[ new ]
  before_action :set_is_error, only: %i[ new create ]

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
      @is_error = true
      append_errors_to_flash(@machi_repo, "作成")
      render :new, status: :unprocessable_entity
    end
  end

  private

  # マイタウン情報を設定する
  def set_mytown_location
    @mytown_address = current_user.mytown_address
    geocoding = Geocoder.search(@mytown_address).first.coordinates
    @mytown_latitude = geocoding[0]
    @mytown_longitude = geocoding[1]
  end

  # エラーメッセージを追加する
  def append_errors_to_flash(record, action_name)
    flash.now[:alert] = [ "まちレポの#{action_name}に失敗しました" ]
    flash.now[:alert] += record.errors.full_messages if record.errors.any?
  end

  # DB登録時のストロングパラメータ取得
  def machi_repo_params
    params.require(:machi_repo).permit(
      :title, :info_level, :category, :description,
      :hotspot_settings, :hotspot_area_radius,
      :address, :latitude, :longitude
    )
  end

  def set_is_error
    @is_error = false
  end
end
