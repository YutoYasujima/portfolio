class CommunitiesController < ApplicationController
  before_action :set_community, only: %i[ show edit update destroy scout members ]
  before_action :set_membership, only: %i[ show scout members ]
  before_action :authorize_edit_and_update, only: %i[ edit update ]
  before_action :authorize_destroy, only: %i[ destroy ]
  before_action :authorize_access, only: %i[ scout ]

  def index
    prefecture_id = current_user.profile.prefecture_id
    municipality_id = current_user.profile.municipality_id
    @search_form = CommunitySearchForm.new(prefecture_id: prefecture_id, municipality_id: municipality_id)
    @communities = @search_form.search_communities.order(updated_at: :desc)
  end

  def search
    search_form = CommunitySearchForm.new(search_params)
    @communities = search_form.search_communities.order(updated_at: :desc)
  end

  def show; end

  def new
    prefecture_id = current_user.profile.prefecture_id
    municipality_id = current_user.profile.municipality_id
    @community = Community.new(prefecture_id: prefecture_id, municipality_id: municipality_id)
  end

  def create
    @community = Community.build(community_params)

    # communityの作成者をリーダー、参加中として登録する
    ActiveRecord::Base.transaction do
      @community.save!

      @community.community_memberships.create!(
        user: current_user,
        role: :leader,
        status: :approved
      )
    end

    redirect_to communities_path, notice: "コミュニティを登録しました"
  rescue
    append_errors_to_flash(@community, "登録")
    render :new, status: :unprocessable_entity
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
    redirect_to communities_path, notice: "\"#{@community.name}\"を解散しました", status: :see_other
  end

  def scout
    @memberships_requested = @community.community_memberships.where(status: :requested).includes(:user, :community).order(updated_at: :desc)
  end

  def members
    memberships = @community.community_memberships.includes(:user, :community)

    @leader_membership       = memberships.find { |m| m.role == "leader" }
    @sub_leaders_memberships = memberships.select { |m| m.role == "sub" }
    @members_memberships     = memberships.select { |m| m.role == "general" && m.status == "approved" }
  end

  private

  def set_community
    community_id = params[:community_id] || params[:id]
    @community = Community.find(community_id)
  end

  def set_membership
    @membership = CommunityMembership.find_by(community_id: @community, user_id: current_user.id)
  end

  # edit・updateのユーザー権限判定
  def authorize_edit_and_update
    unless current_user.leader_or_sub_in?(@community)
      redirect_to community_path(@community), alert: "この操作を行う権限がありません"
    end
  end

  # destroyのユーザー権限判定
  def authorize_destroy
    unless current_user.leader_in?(@community)
      redirect_to community_path(@community), alert: "この操作を行う権限がありません"
    end
  end

  # 閲覧権限判定
  def authorize_access
    unless current_user.approved_in?(@community)
      redirect_to community_path(@community), alert: "この操作を行う権限がありません"
    end
  end

  # エラーメッセージを追加する
  def append_errors_to_flash(record, action_name)
    flash.now[:alert] = [ "コミュニティの#{action_name}に失敗しました" ]
    flash.now[:alert] += record.errors.full_messages if record.errors.any?
  end

  def community_params
    params.require(:community).permit(:name, :prefecture_id, :municipality_id, :description, :icon, :icon_cache)
  end

  # 検索時のストロングパラメータ取得
  def search_params
    params.fetch(:search, {}).permit(
      :name, :prefecture_id, :municipality_id
    )
  end
end
