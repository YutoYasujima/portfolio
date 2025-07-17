class CommunitiesController < ApplicationController
  before_action :set_community, only: %i[ show edit update destroy ]

  def index
    @communities = Community.all.order(created_at: :desc)
  end

  def show; end

  def new
    @community = Community.new
  end

  def create
    @community = Community.build(community_params)

    if @community.save
      redirect_to communities_path, notice: "コミュニティを登録しました"
    else
      append_errors_to_flash(@community, "登録")
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @community.update(community_params)
      redirect_to community_path(@community), notice: "コミュニティ情報を更新しました"
    else
      append_errors_to_flash(@community, "更新")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @community.destroy!
    redirect_to communities_path, notice: "\"#{@community.name}\"を削除しました", status: :see_other
  end

  private

  # エラーメッセージを追加する
  def append_errors_to_flash(record, action_name)
    flash.now[:alert] = [ "コミュニティの#{action_name}に失敗しました" ]
    flash.now[:alert] += record.errors.full_messages if record.errors.any?
  end

  def set_community
    @community = Community.find(params[:id])
  end

  def community_params
    params.require(:community).permit(:name, :prefecture_id, :municipality_id, :description, :icon, :icon_cache)
  end
end
