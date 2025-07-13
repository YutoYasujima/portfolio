class UsersController < ApplicationController
  include InfiniteScroll

  USER_PER_PAGE = 12

  # フォロー一覧
  def followings
    total_records = current_user.followings.includes(:profile).order(updated_at: :desc)
    load_init_data("users", total_records, USER_PER_PAGE)
    @followings = @records
    @followings_count = @total_records_count
  end

  # フォロー一覧の無限スクロール
  def load_more_followings
    total_records = current_user.followings.includes(:profile).order(updated_at: :desc)
    load_more_data("users", total_records, USER_PER_PAGE)
    respond_to do |format|
      format.turbo_stream
    end
  end
end
