class PasswordMailer < ApplicationMailer
  def password_change_request
    @user = params[:user]
    @token = params[:token]
    @reset_link = edit_accounts_password_url(token: @token)

    mail(to: @user.email, subject: "パスワード変更のご案内")
  end

  def password_changed_notification(user)
    @user = user
    mail(to: @user.email, subject: "パスワードが変更されました")
  end
end
