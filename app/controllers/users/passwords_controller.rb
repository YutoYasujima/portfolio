# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    email = resource_params[:email].to_s.strip

    if email.blank?
      flash.now[:alert] = "メールアドレスを入力してください"
      self.resource = resource_class.new # フォーム再描画に必要
      render :new, status: :unprocessable_entity
      return
    end

    self.resource = resource_class.find_by(email: email)

    if resource.nil?
      # メールアドレスが存在しない場合はDeviseのデフォルト動作
      flash.now[:alert] = "入力されたメールアドレスは登録されていません"
      self.resource = resource_class.new # フォーム再描画に必要
      render :new, status: :unprocessable_entity
    elsif resource.provider.present?
      # Google認証ユーザーにはパスワードリセットメールを送らない
      flash.now[:alert] = "Google認証で登録されたアカウントのため、パスワードのリセットはできません"
      render :new, status: :unprocessable_entity
    else
      # 通常のメールアドレス・パスワードユーザーにはメール送信
      super
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
