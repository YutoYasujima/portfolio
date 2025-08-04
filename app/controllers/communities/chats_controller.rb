class Communities::ChatsController < ApplicationController
  before_action :set_community_and_membership, only: %i[ index load_more ]
  before_action :authorize_access, only: %i[ index ]

  CHAT_PER_PAGE = 15

  def index
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

  # 無限スクロール用データ取得
  def load_more
    # チャット初期表示時のスナップショット取得
    snapshot_time = Time.at(session[:community_chats_snapshot_time].to_i)
    cursor_created_at = Time.at(params[:previous_last_created].to_i)
    cursor_id = params[:previous_last_id].to_i

    # 最終ページ判定のため1件多く取得
    raw_chats = @community.chats.includes(:user).where("created_at < ? OR (created_at = ? AND id < ?)", cursor_created_at, cursor_created_at, cursor_id).order(created_at: :desc, id: :desc).limit(CHAT_PER_PAGE + 1)

    # 最終ページ判定
    @is_last_page = raw_chats.size <= CHAT_PER_PAGE

    # 表示分切り出し
    @chats = raw_chats.first(CHAT_PER_PAGE)

    # 取得データ中最も古い日付を取得
    @new_prev_date = @chats.last&.created_at&.to_date

    respond_to do |format|
      format.turbo_stream
    end
  end

  # DB登録とブロードキャスト
  def create
    community = Community.find(params[:community_id])
    chat = community.chats.build(chat_params)

    unless chat.save
      render json: {
        status: "ng", errors: chat.errors.full_messages
      }, status: :unprocessable_entity
      return
    end

    # reloadでCarrierWaveの保存後のimage.urlを正確に取得
    chat.reload

    # Action Cableで他のユーザーにも通知
    ActionCable.server.broadcast "community_chat_#{community.id}", {
      type: "create",
      chat_id: chat.id
    }

    render json: { status: "ok" }
  end

  # チャットパーシャル取得
  def render_chat
    @chat = Chat.find(params[:id])
    @user = @chat.user
    @community = @chat.chatable

    # @chatが本当にcommunity_idのまちレポに属するのか確認
    unless @community.id == params[:community_id].to_i
      head :forbidden and return
    end

    @other_chats_on_same_day_exist = @community.chats.where(created_at: @chat.created_at.to_date.all_day).where.not(id: @chat.id).exists?

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    @community = @chat.chatable

    @chat.destroy!

    # Action Cableで他のユーザーにも通知
    ActionCable.server.broadcast "community_chat_#{@community.id}", {
      type: "destroy",
      chat_id: @chat.id,
      user_id: current_user.id
    }

    # 自身のチャットはTurbo Streamで画面から削除
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  # 閲覧権限判定
  def authorize_access
    unless current_user.approved_in?(@community)
      redirect_to community_path(@community), alert: "この操作を行う権限がありません"
    end
  end

  def set_community_and_membership
    @community = Community.find(params[:community_id])
    @membership = CommunityMembership.find_by(community_id: @community.id, user_id: current_user.id)
  end

  def chat_params
    params.require(:chat).permit(:message, :image).merge(user: current_user)
  end
end
