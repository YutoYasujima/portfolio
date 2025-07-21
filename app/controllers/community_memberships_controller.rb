class CommunityMembershipsController < ApplicationController
  # before_action :set_community, only: %i[ join ]
  before_action :set_membership, only: %i[ approve reject cancel withdraw ]

  # 参加申請
  def join
    community = Community.find(params[:id])
    # 参加中のユーザーは拒否
    if current_user.approved_in?(community)
      redirect_to community_path(community), alert: "既にこのコミュニティに参加しています"
      return
    end

    @membership = CommunityMembership.find_or_initialize_by(user: current_user, community: community)

    @status = "requested"
    @membership.status = @status
    @membership.role = "general"

    if @membership.save
      flash.now[:notice] = "参加をリクエストしました"
    else
      flash.now[:alert] = "参加リクエストに失敗しました"
    end
  end

  # 参加
  def approve
    community = @membership.community
    # リーダーまたはサブリーダーのみ承認できる
    unless current_user.leader_or_sub_in?(community)
      redirect_to community_path(community), alert: "操作を行う権限がありません"
      return
    end

    @user = @membership.user
    if @membership&.requested? && @membership.update(status: :approved)
      flash.now[:notice] = "参加を承認しました"
    else
      flash.now[:alert] = "承認できませんでした"
    end
  end

  # 参加拒否
  def reject
    community = @membership.community
    # リーダーまたはサブリーダーのみ拒否できる
    unless current_user.leader_or_sub_in?(community)
      redirect_to community_path(community), alert: "操作を行う権限がありません"
      return
    end

    @user = @membership.user
    if @membership&.requested? && @membership.update(status: :rejected)
      flash.now[:notice] = "参加を断りました"
    else
      flash.now[:alert] = "参加を断れませんでした"
    end
  end

  # 申請キャンセル
  def cancel
    community = @membership.community
    # 参加中のユーザーは拒否
    if current_user.approved_in?(community)
      redirect_to community_path(community), alert: "既にこのコミュニティに参加しています"
      return
    end

    @previous_status = @membership.status
    if @membership.update(status: :cancelled, role: :general)
      flash.now[:notice] = "取り消しました"
    else
      flash.now[:alert] = "取り消しできませんでした"
    end
  end

  # 自主退会
  def withdraw
    community = @membership.community
    # 非参加中のユーザーは拒否
    unless current_user.approved_in?(community)
      redirect_to community_path(community), alert: "このコミュニティに参加していません"
      return
    end

    # リーダーは退会できない
    if current_user.leader_in?(community)
      redirect_to community_path(community), alert: "リーダーは退会できません"
      return
    end

    if @membership.update(status: :withdrawn, role: :general)
      redirect_to community_path(community), notice: "退会しました"
    else
      redirect_to community_path(community), alert: "退会できませんでした"
    end
  end


  private

  # def set_community
  #   @community = Community.find(params[:id])
  # end

  def set_membership
    @membership = CommunityMembership.find(params[:id])
  end
end
