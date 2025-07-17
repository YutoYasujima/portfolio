class CommunitiesController < ApplicationController
  def index
    @communities = Community.all.order(created_at: :desc)
  end

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

  private

  # エラーメッセージを追加する
  def append_errors_to_flash(record, action_name)
    flash.now[:alert] = [ "コミュニティの#{action_name}に失敗しました" ]
    flash.now[:alert] += record.errors.full_messages if record.errors.any?
  end

  def community_params
    params.require(:community).permit(:name, :prefecture_id, :municipality_id, :description, :icon, :icon_cache)
  end
end
