class Accounts::DeactivationsController < ApplicationController
  before_action :authenticate_user!

  def confirm; end

  def destroy
    resource = current_user
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(:user)
    redirect_to root_path, status: :see_other, notice: "アカウントを削除しました"
  end
end
