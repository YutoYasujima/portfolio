class CommunityChatChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    @community = Community.find(params[:community_id])
    stream_from "community_chat_#{@community.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
