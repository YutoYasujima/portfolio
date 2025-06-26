class ProfilesController < ApplicationController
  skip_before_action :ensure_profile_created, only: %i[ new create ]

  def new
    @profile = Profile.new
  end

  def create
    @profile = current_user.build_profile(profile_params)
    if @profile.save
      redirect_to machi_repos_path, notice: "プロフィールを登録しました"
    else
      append_errors_to_flash(@profile, "登録")
      render :new, status: :unprocessable_entity
    end
  end

  private

  # エラーメッセージを追加する
  def append_errors_to_flash(record, action_name)
    flash.now[:alert] = [ "プロフィールの#{action_name}に失敗しました" ]
    flash.now[:alert] += record.errors.full_messages if record.errors.any?
  end

  def profile_params
    params.require(:profile).permit(:nickname, :prefecture_id, :municipality_id)
  end
end
