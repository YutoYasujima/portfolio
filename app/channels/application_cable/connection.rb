module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # クラスにcurrent_userを属性として追加
    identified_by :current_user

    # WebSocketの接続時にcurrent_userを設定
    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # env['warden'].userでDeviseを通じてログイン中のユーザーを取得
      if verified_user = env["warden"].user
        verified_user
      else
        # ログイン中のユーザーを取得できない場合、WebSocket接続を拒否
        reject_unauthorized_connection
      end
    end
  end
end
