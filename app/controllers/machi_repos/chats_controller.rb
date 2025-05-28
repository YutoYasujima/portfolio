class MachiRepos::ChatsController < ApplicationController
  def index
    @machi_repo = MachiRepo.includes(user: :profile).find(params[:machi_repo_id])
    @chats = @machi_repo.chats.includes(:user).order(created_at: :desc).page(params[:page]).per(12)
  end

  def create
    machi_repo = MachiRepo.find(params[:machi_repo_id])
    chat = machi_repo.chats.build(chat_params)

    unless chat.save
      flash.now[:alert] = [ "画像のアップロードに失敗しました" ]
      flash.now[:alert] += chat.errors.full_messages if chat.errors.any?
      render json: {
        status: "ng", errors: chat.errors.full_messages
      }, status: :unprocessable_entity
      return
    end

    # reloadでCarrierWaveの保存後のimage.urlを正確に取得
    chat.reload

    # Action Cableで他のユーザーにも通知
    ActionCable.server.broadcast "machi_repo_chat_#{chat.chatable.id}", {
      user_id: chat.user_id,
      nickname: chat.user.profile.nickname,
      image_url: chat.image.url,
      time: chat.created_at
    }

    render json: { status: "ok" }
  end

  private

  def chat_params
    params.require(:chat).permit(:image).merge(user: current_user)
  end
end
