# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  # def create
  #   super
  # end

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
