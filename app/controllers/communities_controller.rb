class CommunitiesController < ApplicationController
  before_action :set_community, only: %i[ show edit update destroy scout scout_search members ]
  before_action :set_membership, only: %i[ show scout members ]
  before_action :authorize_edit_and_update, only: %i[ edit update ]
  before_action :authorize_destroy, only: %i[ destroy ]
  before_action :authorize_access, only: %i[ scout ]

  def index
    clear_community_search_values! if params[:clear].present?

    # 検索フォームの値設定
    raw_search_params = if stored_community_search_values.present?
                          stored_community_search_values
                        else
                          {
                            prefecture_id: current_user.profile.prefecture_id,
                            municipality_id: current_user.profile.municipality_id
                          }
                        end
    @search_form = CommunitySearchForm.new(raw_search_params)
    @communities = @search_form.search_communities(current_user)
    # community_idをキー、各コミュニティにおけるユーザーの所属状態statusをバリューとしたハッシュを取得する
    @memberships_by_community_id = current_user.community_memberships.index_by(&:community_id)
  end

  def community_search
    search_form = CommunitySearchForm.new(community_search_params)
    # sessionに画面表示の条件を保持しておく
    store_community_search_values!(search_form.attributes)
    @communities = search_form.search_communities(current_user)
    # community_idをキー、各コミュニティにおけるユーザーの所属状態statusをバリューとしたハッシュを取得する
    @memberships_by_community_id = current_user.community_memberships.index_by(&:community_id)
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
    # 参加希望ユーザー
    @memberships_requested = @community.community_memberships.where(status: :requested).includes(:user, :community).order(updated_at: :desc)
    # スカウト中ユーザー
    @memberships_invited = @community.community_memberships.where(status: :invited).includes(:user, :community).order(updated_at: :desc)
    # ユーザー検索
    prefecture_id = @community.prefecture_id
    municipality_id = @community.municipality_id
    @search_form = UserSearchForm.new(prefecture_id: prefecture_id, municipality_id: municipality_id)
    @scout_candidates = @search_form.search_user_for_scout(@community)
  end

  def scout_search
    search_form = UserSearchForm.new(scout_search_params)
    @scout_candidates = search_form.search_user_for_scout(@community)
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

  # コミュニティ検索時のストロングパラメータ取得
  def community_search_params
    params.fetch(:search, {}).permit(
      :name, :prefecture_id, :municipality_id
    )
  end

  # スカウトユーザー検索時のストロングパラメータ取得
  def scout_search_params
    params.fetch(:search, {}).permit(
      :nickname, :identifier, :prefecture_id, :municipality_id
    )
  end

  # セッションから検索条件を取得
  def stored_community_search_values
    session[:communities_home_search_values]
  end

  # セッションに検索条件を保存
  def store_community_search_values!(values)
    session[:communities_home_search_values] = values
  end

  # セッションをクリア
  def clear_community_search_values!
    session.delete(:communities_home_search_values)
  end
end
