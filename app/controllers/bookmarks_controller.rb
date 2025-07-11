class BookmarksController < ApplicationController
  def create
    @machi_repo = MachiRepo.find(params[:machi_repo_id])
    current_user.bookmark(@machi_repo)
  end

  def destroy
    @machi_repo = current_user.bookmarks.find(params[:id]).machi_repo
    current_user.unbookmark(@machi_repo)
  end
end
