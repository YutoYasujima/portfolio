class Communities::ChatsController < ApplicationController
  before_action :set_community_and_membership, only: %i[ index load_more ]
  before_action :authorize_access, only: %i[ index ]

  CHAT_PER_PAGE = 15

  def index
    # 無限スクロール対策のため、UNIXタイムスタンプで保存
    snapshot_time = Time.current
    session[:community_chats_snapshot_time] = snapshot_time.to_i

    # 最終ページ判定のため1件多く取得
    raw_chats = @community.chats.includes(user: [ :profile, :community_memberships ]).where("created_at <= ?", snapshot_time).order(created_at: :desc, id: :desc).limit(CHAT_PER_PAGE + 1)

    # 最終ページ判定
    @is_last_page = raw_chats.size <= CHAT_PER_PAGE

    # 表示分切り出し
    @chats = raw_chats.first(CHAT_PER_PAGE)

    # コミュニティに参加しているユーザーのID取得
    set_approved_user_ids

    # 既読数取得
    set_read_counts_hash
  end

  # 無限スクロール用データ取得
  def load_more
    # チャット初期表示時のスナップショット取得
    snapshot_time = Time.at(session[:community_chats_snapshot_time].to_i)
    cursor_created_at = Time.at(params[:previous_last_created].to_i)
    cursor_id = params[:previous_last_id].to_i

    # 最終ページ判定のため1件多く取得
    raw_chats = @community.chats.includes(user: [ :profile, :community_memberships ]).where("created_at < ? OR (created_at = ? AND id < ?)", cursor_created_at, cursor_created_at, cursor_id).order(created_at: :desc, id: :desc).limit(CHAT_PER_PAGE + 1)

    # 最終ページ判定
    @is_last_page = raw_chats.size <= CHAT_PER_PAGE

    # 表示分切り出し
    @chats = raw_chats.first(CHAT_PER_PAGE)

    # 取得データ中最も古い日付を取得
    @new_prev_date = @chats.last&.created_at&.to_date

    # コミュニティに参加しているユーザーのID取得
    set_approved_user_ids

    # 既読数取得
    set_read_counts_hash

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

    @read_counts_hash = {}

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    @community = @chat.chatable

    @chat.destroy!

    @other_chats_on_same_day_exist = @community.chats.where(created_at: @chat.created_at.to_date.all_day).where.not(id: @chat.id).exists?

    # Action Cableで他のユーザーにも通知
    ActionCable.server.broadcast "community_chat_#{@community.id}", {
      type: "destroy",
      chat_id: @chat.id,
      user_id: current_user.id,
      other_chats_on_same_day: @other_chats_on_same_day_exist ? nil : @chat.created_at.to_date
    }

    # 自身のチャットはTurbo Streamで画面から削除
    respond_to do |format|
      format.turbo_stream
    end
  end

  # チャットの既読情報更新
  def mark_as_read
    @community = Community.find(params[:community_id])
    last_read_chat_id = params[:last_read_chat_id].to_i

    read = CommunityChatRead.find_or_initialize_by(user: current_user, community: @community)
    last_read_chat_id_before_update = read&.last_read_chat_id || 0

    # IDが進んでいる場合のみ更新
    if read.last_read_chat_id.nil? || last_read_chat_id > read.last_read_chat_id
      read.last_read_chat_id = last_read_chat_id
      read.save

      # 更新前と更新後のlast_read_chat_id間のチャットの既読数を
      # クライアント側でインクリメントする
      ActionCable.server.broadcast "community_chat_#{@community.id}", {
        type: "read",
        user_id: current_user.id,
        last_read_chat_id_before_update: last_read_chat_id_before_update,
        last_read_chat_id_after_update: read.last_read_chat_id
      }
    end

    head :ok
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

  # 既読数取得
  def set_read_counts_hash
    # 自分のチャットIDだけを抽出
    # 自分以外の既読情報を取得
    my_chat_ids = @chats.select { |chat| chat.user_id == current_user.id }.map(&:id)

    # コミュニティに参加中のユーザーID取得
    approved_users = CommunityMembership.where(community_id: @community.id, status: "approved").select(:user_id)

    # 自分のチャットに対して、既読したユーザ－のIDを配列として保持
    # 自分のチャットIDをキー、既読ユーザーIDの配列をバリューとしてハッシュを作成
    @read_counts_hash = CommunityChatRead
      .where(community_id: @community.id)
      .where.not(user_id: current_user.id)
      .where(user_id: approved_users)
      .pluck(:user_id, :last_read_chat_id)
      .each_with_object(Hash.new { |h, k| h[k] = [] }) do |(user_id, last_read_chat_id), hash|
        my_chat_ids.each do |chat_id|
          hash[chat_id] << user_id if last_read_chat_id >= chat_id
        end
      end
  end

  # コミュニティに参加しているユーザーのIDを取得する
  def set_approved_user_ids
    @approved_user_ids = @community.community_memberships
      .where(status: "approved")
      .pluck(:user_id)
  end

  def chat_params
    params.require(:chat).permit(:message, :image).merge(user: current_user)
  end
end
