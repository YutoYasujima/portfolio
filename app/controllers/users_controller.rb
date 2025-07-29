class UsersController < ApplicationController
  include InfiniteScroll

  before_action :set_user, only: %i[ communities load_more_communities ]

  USER_PER_PAGE = 12
  COMMUNITY_PER_PAGE = 12

  # フォロー一覧
  def followings
    total_records = current_user.followings.includes(:profile).order(updated_at: :desc)
    load_init_data("users", total_records, USER_PER_PAGE)
    @followings = @records
    @followings_count = @total_records_count
  end

  # フォロー一覧の無限スクロール
  def load_more_followings
    total_records = current_user.followings.includes(:profile).order(updated_at: :desc)
    load_more_data("users", total_records, USER_PER_PAGE)
    respond_to do |format|
      format.turbo_stream
    end
  end

  # 参加中コミュニティ一覧
  def communities
    total_records = @user.approved_communities_with_member_count
    load_init_data("communities", total_records, COMMUNITY_PER_PAGE)
    @communities = @records
    @communities_count = @total_records_count
    # community_idをキー、各コミュニティにおけるユーザーの所属状態statusをバリューとしたハッシュを取得する
    @memberships_by_community_id = current_user.community_memberships.index_by(&:community_id)
  end

  # 参加中コミュニティ一覧の無限スクロール
  def load_more_communities
    total_records = @user.approved_communities_with_member_count
    load_more_data("communities", total_records, COMMUNITY_PER_PAGE)
    # community_idをキー、各コミュニティにおけるユーザーの所属状態statusをバリューとしたハッシュを取得する
    @memberships_by_community_id = current_user.community_memberships.index_by(&:community_id)
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
