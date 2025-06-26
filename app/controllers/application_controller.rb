class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :ensure_profile_created

  add_flash_types :success, :error

  # ログイン後の遷移先を指定する
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || machi_repos_path
  end

  private

  # ログイン中のUserに紐付くProfileがあるか確認
  def ensure_profile_created
    return unless user_signed_in?

    # 除外したいコントローラーやアクション（無限ループ防止）
    return if controller_path == "profiles" && %w[new create].include?(action_name)

    # Profileがないなら登録画面にリダイレクト
    unless current_user.profile.present?
      redirect_to new_profile_path, notice: "プロフィールを登録してください"
    end
  end
end
