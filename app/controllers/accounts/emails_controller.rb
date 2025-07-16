class Accounts::EmailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_devise_mapping, only: %i[ edit update ]

  def edit
    # 画面にデータを表示する必要がない
    @user = User.new(id: current_user.id)
  end

  def update
    @user = User.find(current_user.id)
    @user.email = email_update_params[:email]

    # バリデーションチェック
    @user.valid?(:email_update)
    unless @user.valid_password?(email_update_params[:current_password])
      @user.errors.add(:current_password, "が正しくありません")
    end

    # メールアドレスを更新
    if @user.errors.empty? && @user.save
      sign_out(current_user)
      # DeviseのConfirmableを使っている場合、自動的に確認メールが送信される
      redirect_to root_path, notice: "新しいメールアドレス宛に確認メールをお送りしています。
メールに記載されたリンクをクリックして、変更を完了してください。"
    else
      # current_userの値を元に戻す
      flash.now[:alert] = @user.errors.full_messages
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def email_update_params
    params.require(:user).permit(:email, :current_password)
  end

  def set_devise_mapping
    @devise_mapping = Devise.mappings[:user]
  end
end
