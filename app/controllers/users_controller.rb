class UsersController < ApplicationController
  def followings
    @followings = current_user.followings.includes(:profile).order(updated_at: :desc)
  end
end
