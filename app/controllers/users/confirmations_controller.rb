# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      # 通常通りリダイレクト（flash[:notice] は Devise が自動で設定）
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    else
      # バリデーションエラー時に flash を手動設定
      # オーバーライドで下記の１行だけ追記
      flash.now[:alert] = resource.errors.full_messages
      respond_with(resource)
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  #   super
  # end

  protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # ユーザー登録確認メールのリンクをクリックした後の遷移先
  def after_confirmation_path_for(resource_name, resource)
    # ログイン状態にするなら sign_in(resource) を使ってから遷移
    sign_in(resource) if resource.present?
    machi_repos_path
  end
end
