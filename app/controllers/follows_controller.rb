class FollowsController < ApplicationController
  def create
    @user = User.find(params[:user_id])
    current_user.follow(@user)
  end

  def destroy
    @user = current_user.followings.find(params[:id])
    current_user.unfollow(@user)
  end
end
