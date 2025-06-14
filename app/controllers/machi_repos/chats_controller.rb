class MachiRepos::ChatsController < ApplicationController
  before_action :set_machi_repo, only: %i[ index load_more ]

  CHAT_PER_PAGE = 15

  def index
    # 無限スクロール対策のため、UNIXタイムスタンプで保存
    snapshot_time = Time.current
    session[:machi_repo_chats_snapshot_time] = snapshot_time.to_i

    # 最終ページ判定のため1件多く取得
    raw_chats = @machi_repo.chats.includes(:user).where("created_at <= ?", snapshot_time).order(created_at: :desc, id: :desc).limit(CHAT_PER_PAGE + 1)

    # 最終ページ判定
    @is_last_page = raw_chats.size <= CHAT_PER_PAGE

    # 表示分切り出し
    @chats = raw_chats.first(CHAT_PER_PAGE)
  end

  # 無限スクロール用データ取得
  def load_more
    # チャット初期表示時のスナップショット取得
    snapshot_time = Time.at(session[:machi_repo_chats_snapshot_time].to_i)
    cursor_created_at = Time.at(params[:previous_last_created].to_i)
    cursor_id = params[:previous_last_id].to_i

    # 最終ページ判定のため1件多く取得
    raw_chats = @machi_repo.chats.includes(:user).where("created_at < ? OR (created_at = ? AND id < ?)", cursor_created_at, cursor_created_at, cursor_id).order(created_at: :desc, id: :desc).limit(CHAT_PER_PAGE + 1)

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
    machi_repo = MachiRepo.find(params[:machi_repo_id])
    chat = machi_repo.chats.build(chat_params)

    unless chat.save
      render json: {
        status: "ng", errors: chat.errors.full_messages
      }, status: :unprocessable_entity
      return
    end

    # reloadでCarrierWaveの保存後のimage.urlを正確に取得
    chat.reload

    # Action Cableで他のユーザーにも通知
    ActionCable.server.broadcast "machi_repo_chat_#{machi_repo.id}", {
      type: "create",
      chat_id: chat.id
    }

    render json: { status: "ok" }
  end

  # チャットパーシャル取得
  def render_chat
    @chat = Chat.find(params[:id])
    @user = @chat.user
    @machi_repo = @chat.chatable

    # @chatが本当にmachi_repo_idのまちレポに属するのか確認
    unless @machi_repo.id == params[:machi_repo_id].to_i
      head :forbidden and return
    end

    @other_chats_on_same_day_exist = @machi_repo.chats.where(created_at: @chat.created_at.to_date.all_day).where.not(id: @chat.id).exists?

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    @machi_repo = @chat.chatable

    @chat.destroy!

    # Action Cableで他のユーザーにも通知
    ActionCable.server.broadcast "machi_repo_chat_#{@machi_repo.id}", {
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

  def set_machi_repo
    @machi_repo = MachiRepo.includes(user: :profile).find(params[:machi_repo_id])
  end

  def chat_params
    params.require(:chat).permit(:message, :image).merge(user: current_user)
  end
end
