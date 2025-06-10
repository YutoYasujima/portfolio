# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    # @user = user.new({})と同義。空のUserインスタンスを作成。
    build_resource({})
    # resource(Deviseが用意している)は、この場合Userのインスタンス。
    # 下記はuser.build_profileに相当。
    # これをしないとビューでfields_forの中が表示されない。
    resource.build_profile  # プロフィールをビルド
    # resourceをビューに渡している。
    respond_with resource
  end

  # POST /resource
  def create
    # @user = user.new(user_params)のようなもの
    # 「accepts_nested_attributes_for :profile」を設定しているため、
    # Profileも一緒に保存される。
    build_resource(sign_up_params)

    resource.save
    # createメソッドがブロック付きで呼び出されたら、
    # そのブロックにresource(Userのデータ)を渡して実行する。
    # カスタマイズを行いたい場合に下記を実行すれば良い。
    yield resource if block_given?
    # 保存に成功してDBにレコードができたかどうかを確認。
    if resource.persisted?
      # Deviseで「このユーザーは今すぐログイン可能か？」をチェックするメソッド。
      # メール認証用のconfirmableモジュール使用時はfalseになる。
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        # 確認用メールを送ったというメッセージを表示。
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        # Devise内部のメソッド。
        # DeviseがSessionに一時的に保存していたデータを削除する。
        # Sessionをログイン前のクリーンな状態に保っておく
        expire_data_after_sign_in!
        # ログインしていなユーザー用のページに遷移。デフォルトはroot_path
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      # パスワード入力欄を空にする。
      clean_up_passwords resource
      # Deviseのメソッド。
      # バリデーションエラー時の、最小パスワード長の値をビューで使えるようにする。
      # デフォルトは「6文字」
      set_minimum_password_length
      flash[:alert] = resource.errors.full_messages
      # エラー付きのフォームをもう一度表示する。
      respond_with resource
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # パラメータのサニタイズ。登録時paramsの中身を制限できる。
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :email, :password, :password_confirmation, :agreement, profile_attributes: [ :nickname, :prefecture_id, :municipality_id ] ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
