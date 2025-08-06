# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end

  # More info at:
  # https://github.com/heartcombo/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      # ログイン後の遷移先はappclication_controllerのafter_sign_in_path_forメソッドで決まる
      flash[:notice] = "ログインしました"
      # remember_token を明示的に発行
      @user.remember_me = true
      sign_in_and_redirect @user, event: :authentication
    else
      flash[:alert] = [ "Googleログインに失敗しました" ]
      flash[:alert] += @user.errors.full_messages if @user.errors.any?
      session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_session_path
    end
  end

  # OmniAuth が自動的に失敗した場合（ユーザーがキャンセルした、認証が壊れた等）に呼ばれる
  # トップページへリダイレクトして、失敗メッセージを表示
  def failure
    redirect_to new_user_session_path, alert: "Googleログインに失敗しました"
  end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
