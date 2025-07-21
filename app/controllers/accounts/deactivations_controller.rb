class Accounts::DeactivationsController < ApplicationController
  before_action :authenticate_user!

  def confirm; end

  def destroy
    # リーダーのコミュニティがある場合は削除できない
    if current_user.community_memberships.where(role: :leader).exists?
      # redirect_to confirm_accounts_deactivation_path, status: :unprocessable_entity, alert: "リーダーになっているコミュニティがあります"
      flash.now[:alert] = "リーダーになっているコミュニティがあります"
      render :confirm, status: :unprocessable_entity
      return
    end

    resource = current_user
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(:user)
    redirect_to root_path, status: :see_other, notice: "アカウントを削除しました"
  end
end
