class Accounts::PasswordsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_change_password_token, only: %i[ edit update ]

  def new; end

  def create
    @user = current_user
    # Deviseのトークンジェネレーターを使ってトークン生成
    raw_token, enc_token = Devise.token_generator.generate(User, :change_password_token)

    # 2つのカラムのみを更新する。
    @user.update_columns(
      change_password_token: enc_token,
      change_password_sent_at: Time.current
    )

    # メールを送信(パスワードリセットのものを流用)
    PasswordMailer.with(user: @user, token: raw_token).password_change_request.deliver_now

    redirect_back fallback_location: machi_repos_path, notice: "パスワード変更用のメールを送信しました。"
  end

  def edit
    @user.change_password_token = @raw_token
  end

  def update
    if @user.update(user_params)
      # トークンを無効化して再利用防止
      @user.update(change_password_token: nil, change_password_sent_at: nil)

      # 強制的にログイン状態にする
      bypass_sign_in(@user)

      # パスワード変更完了メール送信
      PasswordMailer.password_changed_notification(@user).deliver_now

      redirect_to new_accounts_password_path, notice: "パスワードが変更されました。"
    else
      @user.change_password_token = @raw_token
      flash.now[:alert] = @user.errors.full_messages
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # トークンの検証
  def validate_change_password_token
    # 生のトークンを取得する
    @raw_token = params.dig(:token) || params.dig(:user, :change_password_token)
    # トークンを暗号化
    encrypted_token = Devise.token_generator.digest(User, :change_password_token, @raw_token)

    # change_password_tokenカラムは一意になっているため、検証になる。
    @user = User.find_by(change_password_token: encrypted_token)

    # 取得できる または 期限以内かを確認する。
    if @user.nil? || !@user.change_password_period_valid?
      redirect_to new_accounts_password_path, alert: "リンクは無効または期限切れです。"
    end
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
