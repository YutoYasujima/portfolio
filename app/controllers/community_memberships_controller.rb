class CommunityMembershipsController < ApplicationController
  before_action :set_community

  def join
    # 参加中のユーザーは拒否
    if current_user.approved_in?(@community)
      redirect_to community_path(@community), alert: "既にこのコミュニティに参加しています"
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

  def approve
    # リーダーまたはサブリーダーのみ承認できる
    unless current_user.leader_or_sub_in?(@community)
      redirect_to community_path(@community), alert: "操作を行う権限がありません"
      return
    end

    @user_id = params[:user_id]
    membership = CommunityMembership.find_by(community_id: params[:id], user_id: @user_id)
    if membership&.requested? && membership.update(status: :approved)
      flash.now[:notice] = "参加を承認しました"
    else
      flash.now[:alert] = "承認できませんでした"
    end
  end

  def reject
    # リーダーまたはサブリーダーのみ承認できる
    unless current_user.leader_or_sub_in?(@community)
      redirect_to community_path(@community), alert: "操作を行う権限がありません"
      return
    end

    @user_id = params[:user_id]
    membership = CommunityMembership.find_by(community_id: params[:id], user_id: @user_id)
    if membership&.requested? && membership.update(status: :rejected)
      flash.now[:notice] = "参加を断りました"
    else
      flash.now[:alert] = "参加を断れませんでした"
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
