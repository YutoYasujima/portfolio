class MachiRepoChatChannel < ApplicationCable::Channel
  def subscribed
    # このチャネルのインスタンスは購読しているクライアントがいる限り破棄されない
    # そのためここで取得した@machi_repoは保持され、別のメソッドでも使える
    @machi_repo = MachiRepo.find(params[:machi_repo_id])
    stream_from "machi_repo_chat_#{@machi_repo.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_chat(data)
    # 画像データはWebSocket通信では送信できないため、
    # ここでは画像の保存は行わず、テキストデータのみ取り扱う

    chat = Chat.create(message: data["message"], user: current_user, chatable: @machi_repo)
    # ビューに返すオブジェクト
    ActionCable.server.broadcast "machi_repo_chat_#{@machi_repo.id}",
      {
        user_id: current_user.id,
        nickname: current_user.profile.nickname,
        message: chat.message,
        time: chat.created_at
      }
  end
end
