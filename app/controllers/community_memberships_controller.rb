class CommunityMembershipsController < ApplicationController
  before_action :set_community

  def join
    # 参加中のユーザーは拒否
    if current_user.approved_in?(@community)
      redirect_to @community, alert: "既にこのコミュニティに参加しています"
      return
    end

    membership = CommunityMembership.find_or_initialize_by(user: current_user, community: @community)
    @status = "requested"
    membership.status = @status
    membership.role = "general"

    if membership.save
      flash.now[:notice] = "参加をリクエストしました"
    else
      flash.now[:alert] = "参加リクエストに失敗しました"
    end
  end

  def cancel
    @membership = CommunityMembership.find_by(user: current_user, community: @community)
    @previous_status = @membership&.status
    if @membership.update(status: :cancelled, role: :general)
      flash.now[:notice] = "取り消しました"
    else
      flash.now[:alert] = "取り消しできませんでした"
    end
  end

  private

  def set_community
    @community = Community.find(params[:id])
  end
end
