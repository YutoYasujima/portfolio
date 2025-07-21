class CommunityMembershipsController < ApplicationController
  before_action :set_membership, except: :join

  # 参加申請
  def join
    # joinアクションはCommunityMembershipクラスのインスタンスがない場合作成する
    # そのため、params[:id]はCommunityのものを受け取る
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

  # 強制退会
  def kick
    community = @membership.community
    # リーダーのみユーザーを強制退会させられる
    unless current_user.leader_in?(community)
      redirect_to community_path(community), alert: "操作を行う権限がありません"
      return
    end

    user_name = @membership.user.profile.nickname
    if @membership.general? && @membership.update(status: :kicked, role: :general)
      flash.now[:notice] = "\"#{user_name}\"さんに退会してもらいました"
    else
      flash.now[:alert] = "\"#{user_name}\"さんを退会させられませんでした"
    end
  end

  # 役職変更
  def update_role
    community = @membership.community
    @success = false
    # リーダーのみが役職を変更できる
    unless current_user.leader_in?(community)
      redirect_to community_path(community), alert: "操作を行う権限がありません"
      return
    end

    unless CommunityMembership.roles.keys.include?(params[:role])
      redirect_to community_path(community), alert: "無効な操作が行われました"
      return
    end

    # roleの更新
    ActiveRecord::Base.transaction do
      if params[:role] == "leader"
        # リーダー(current_user)を入れ替える
        current_user.membership_for(community).sub!
      end
      @membership.update!(role: params[:role])
      @success = true
    rescue
      flash.now[:alert] = "役職を変更できませんでした"
    end

    if @success
      if params[:role] == "leader"
        # リーダーを入れ替える場合は各ユーザーカードの表示も変える必要があるため、
        # 画面の更新をする
        redirect_to members_communities_path(community_id: community.id), notice: "リーダーを交代しました"
      else
        flash.now[:notice] = "役職を変更しました"
      end
    end
  end

  private

  def set_membership
    @membership = CommunityMembership.find(params[:id])
  end
end
