class MachiRepoChatChannel < ApplicationCable::Channel
  def subscribed
    @machi_repo = MachiRepo.find(params[:machi_repo_id])
    stream_from "machi_repo_chat_#{@machi_repo.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_chat(data)
    user = User.find(data["user_id"])
    chat = Chat.create(message: data["message"], image: data["image"], user: user, chatable: @machi_repo)
    # ビューに返すオブジェクト
    ActionCable.server.broadcast "machi_repo_chat_#{@machi_repo.id}",
      {
        user_id: user.id,
        nickname: user.profile.nickname,
        message: chat.message,
        time: chat.created_at
      }
  end
end
