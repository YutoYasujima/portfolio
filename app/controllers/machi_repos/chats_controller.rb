class MachiRepos::ChatsController < ApplicationController
  def index
    @machi_repo = MachiRepo.includes(user: :profile).find(params[:machi_repo_id])
    @chats = @machi_repo.chats.order(created_at: :desc)
  end
end
