class MachiRepoChatChannel < ApplicationCable::Channel
  def subscribed
    @machi_repo = MachiRepo.find(params[:machi_repo_id])
    stream_from "machi_repo_chat_#{@machi_repo.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def sendChat
    ActionCable.server.broadcast "general", { name: data["name"], body: data["body"] }
    Message.create topic: "general", name: data["name"], body: data["body"]
  end
end
