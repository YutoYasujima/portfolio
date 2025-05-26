class MachiRepoChatsController < ApplicationController
  def show
    @machi_repo = MachiRepo.includes(user: :profile).find(params[:machi_repo_id])
  end
end
