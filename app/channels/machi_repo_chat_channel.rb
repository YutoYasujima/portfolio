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
end
