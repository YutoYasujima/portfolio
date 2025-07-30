class Communities::ChatsController < ApplicationController
  CHAT_PER_PAGE = 15

  def index
    @community = Community.find(params[:community_id])
    @membership = CommunityMembership.find_by(community_id: @community.id, user_id: current_user.id)

    # 無限スクロール対策のため、UNIXタイムスタンプで保存
    snapshot_time = Time.current
    session[:community_chats_snapshot_time] = snapshot_time.to_i

    # 最終ページ判定のため1件多く取得
    raw_chats = @community.chats.includes(:user).where("created_at <= ?", snapshot_time).order(created_at: :desc, id: :desc).limit(CHAT_PER_PAGE + 1)

    # 最終ページ判定
    @is_last_page = raw_chats.size <= CHAT_PER_PAGE

    # 表示分切り出し
    @chats = raw_chats.first(CHAT_PER_PAGE)
  end
end
