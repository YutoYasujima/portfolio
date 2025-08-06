class CommunityMembershipsController < ApplicationController
  COMMUNITY_DISBANDED_MSG = "コミュニティは解散しています"
  ACCOUNT_DELETED_MSG = "そのユーザーはアカウントを削除しています"
  ALREADY_JOINED_COMMUNITY_MSG = "既にコミュニティに参加しています"
  ALREADY_WITHDRAWN_COMMUNITY_MSG = "既にコミュニティを退会しています"

  before_action :set_membership, except: %i[ join invite ]

  # コミュニティ・ユーザー存在確認要否
  #                   | community | user |   実行者   |
  # join              |    〇     |  ✕  |    user    |
  # join_cancel       |    〇     |  ✕  |    user    |
  # invite            |    〇     |  〇  | leader,sub |
  # invite_cancel     |    〇     |  〇  | leader,sub |
  # requested_approve |    〇     |  〇  | leader,sub |
  # requested_reject  |    〇     |  〇  | leader,sub |
  # invite_accept     |    〇     |  ✕  |    user    |
  # invite_reject     |    〇     |  ✕  |    user    |
  # withdraw          |    〇     |  ✕  | sub,member |
  # kick              |    ✕     |  〇  |   leader   |
  # update_role       |    ✕     |  〇  |   leader   |

  # 参加申請
  def join
    # CommunityMembershipデータは作成or検索で取得
    # コミュニティ取得
    community = find_community_from_params_or_redirect(params[:id]) or return

    # 参加中のユーザーは拒否
    return if redirect_if_already_approved(current_user, community)

    @membership = CommunityMembership.find_or_initialize_by(user: current_user, community: community)
    # スカウトされている場合は参加希望できない
    if @membership.persisted? && @membership.invited?
      redirect_to community_path(community), notice: "コミュニティからスカウトされています"
      return
    end

    @membership.assign_attributes(status: :requested, role: :general)

    if @membership.save
      flash.now[:notice] = "参加をリクエストしました"
    else
      flash.now[:alert] = "リクエストに失敗しました"
    end
  end

  # 参加希望キャンセル
  def join_cancel
    # コミュニティ取得
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # 参加中のユーザーは拒否
    return if redirect_if_already_approved(current_user, community)

    if @membership.update(status: :cancelled, role: :general)
      flash.now[:notice] = "参加希望を取り消しました"
    else
      flash.now[:alert] = "参加希望を取り消すことができませんでした"
    end
  end

  # スカウト
  def invite
    # CommunityMembershipデータは作成or検索で取得
    community = find_community_from_params_or_redirect(params[:id]) or return

    # リーダーまたはサブリーダーのみスカウトできる
    return if redirect_unless_leader_or_sub(current_user, community)

    # ユーザーがアカウントを削除していた場合を考える
    # 削除されていてもユーザーカードを削除するためにIDを保持
    @user_id = params[:user_id]
    user = find_user_from_params_or_render(@user_id) or return

    @membership = CommunityMembership.find_or_initialize_by(user: user, community: community)
    # 参加希望がある場合はスカウトできない
    if @membership.persisted? && @membership.requested?
      flash.now[:notice] = "\"#{user.profile.nickname}\"さんから参加希望が出ています"
      return
    end

    @membership.assign_attributes(status: :invited, role: :general)

    if @membership.save
      flash.now[:notice] = "スカウトしました"
    else
      flash.now[:alert] = "スカウトに失敗しました"
    end
  end

  # スカウトキャンセル
  def invite_cancel
    # ユーザーがアカウントを削除していしていても、カードを画面から削除するためにIDを保持
    @user_id = params[:user_id]
    user = find_user_from_params_or_render(@user_id) or return

    # ユーザーが存在しているのにcommunityがnilならコミュニティが解散している
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # リーダーまたはサブリーダーのみスカウトできる
    return if redirect_unless_leader_or_sub(current_user, community)

    # user_idで取得したユーザーと@membershipで取得できるユーザーが違う場合は不正
    return if redirect_if_user_mismatch(user, @membership.user, community)

    # 参加中のユーザーは拒否、ユーザーカードを画面から削除する
    return if render_if_already_approved(user, community)

    if @membership.update(status: :cancelled, role: :general)
      flash.now[:notice] = "スカウトを取り消しました"
    else
      flash.now[:alert] = "スカウトを取り消すことができませんでした"
    end
  end

  # 参加承認
  def requested_approve
    # ユーザーがアカウントを削除していしていても、カードを画面から削除するためにIDを保持
    @user_id = params[:user_id]
    user = find_user_from_params_or_render(@user_id) or return

    # ユーザーが存在しているのにcommunityがnilならコミュニティが解散している
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # リーダーまたはサブリーダーのみ参加承認できる
    return if redirect_unless_leader_or_sub(current_user, community)

    # user_idで取得したユーザーと@membershipで取得できるユーザーが違う場合は不正
    return if redirect_if_user_mismatch(user, @membership.user, community)

    if @membership.requested? && @membership.update(status: :approved)
      flash.now[:notice] = "参加を承認しました"
    else
      flash.now[:alert] = "参加を承認できませんでした"
    end
  end

  # 参加希望お断り
  def requested_reject
    # ユーザーがアカウントを削除していしていても、カードを画面から削除するためにIDを保持
    @user_id = params[:user_id]
    user = find_user_from_params_or_render(@user_id) or return

    # ユーザーが存在しているのにcommunityがnilならコミュニティが解散している
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # リーダーまたはサブリーダーのみ参加承認できる
    return if redirect_unless_leader_or_sub(current_user, community)

    # user_idで取得したユーザーと@membershipで取得できるユーザーが違う場合は不正
    return if redirect_if_user_mismatch(user, @membership.user, community)

    if @membership&.requested? && @membership.update(status: :rejected)
      flash.now[:notice] = "参加を断りました"
    else
      flash.now[:alert] = "参加を断れませんでした"
    end
  end

  # スカウト受け入れ
  def invited_accept
    # ユーザーが存在しているのにcommunityがnilならコミュニティが解散している
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # 参加中のユーザーは拒否
    return if redirect_if_already_approved(current_user, community)

    if @membership.invited? && @membership.update(status: :approved)
      redirect_to community_path(community), notice: "コミュニティに参加しました"
    else
      redirect_to community_path(community), alert: "コミュニティに参加できませんでした"
    end
  end

  # スカウトお断り
  def invited_reject
    # ユーザーが存在しているのにcommunityがnilならコミュニティが解散している
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # 参加中のユーザーは拒否
    return if redirect_if_already_approved(current_user, community)

    if @membership&.invited? && @membership.update(status: :rejected)
      redirect_to community_path(community), notice: "参加を断りました"
    else
      redirect_to community_path(community), alert: "参加を断れませんでした"
    end
  end

  # 自主退会
  def withdraw
    # ユーザーが存在しているのにcommunityがnilならコミュニティが解散している
    community = find_community_form_community_membership_or_redirect(@membership) or return

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
      # チャット既読を削除
      CommunityChatRead.where(user_id: current_user.id, community_id: community.id).destroy_all
      redirect_to community_path(community), notice: "退会しました"
    else
      redirect_to community_path(community), alert: "退会できませんでした"
    end
  end

  # 強制退会
  def kick
    # 強制退会するユーザーがアカウントを削除していた場合
    # 削除されていてもユーザーカードを削除するためにIDを保持
    @user_id = params[:user_id]
    user = find_user_from_params_or_render(@user_id) or return

    # ユーザーが存在しているのにcommunityがnilならコミュニティが解散している
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # ユーザーが退会していないことを確認
    return if render_if_already_withdrawn(user, community)

    # リーダーのみユーザーを強制退会させられる
    return if redirect_unless_leader(current_user, community)

    user_name = user.profile.nickname
    # 強制退会させられるのは通常メンバーのみ
    if @membership.general? && @membership.update(status: :kicked, role: :general)
      # チャット既読を削除
      CommunityChatRead.where(user_id: user.id, community_id: community.id).destroy_all
      flash.now[:notice] = "\"#{user_name}\"さんに退会してもらいました"
    else
      flash.now[:alert] = "\"#{user_name}\"さんを退会させられませんでした"
    end
  end

  # 役職変更
  def update_role
    @success = false
    # 役職変更したいユーザーがアカウントを削除していた場合
    # 削除されていてもユーザーカードを削除するためにIDを保持
    @user_id = params[:user_id]
    user = find_user_from_params_or_render(@user_id) or return

    # 役職変更はリーダーが行う操作のため、コミュニティが無いことは有り得ないが、
    # 上記で取得したユーザーが不正の場合、@membershipがnilの場合もあるため確認
    community = find_community_form_community_membership_or_redirect(@membership) or return

    # user_idで取得したユーザーと@membershipで取得できるユーザーが違う場合は不正
    return if redirect_if_user_mismatch(user, @membership.user, community)

    # ユーザーが退会していないことを確認
    return if render_if_already_withdrawn(user, community)

    # リーダーのみ役職を変更できる
    return if redirect_unless_leader(current_user, community)

    # パラメータに不正な入力が無いことを確認
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

    return unless @success

    if params[:role] == "leader"
      # リーダーを入れ替える場合は各ユーザーカードの表示も変える必要があるため、
      # 画面の再読込をする
      redirect_to members_communities_path(community_id: community.id), notice: "リーダーを交代しました"
    else
      flash.now[:notice] = "役職を変更しました"
    end
  end

  private

  def set_membership
    @membership = CommunityMembership.find_by(id: params[:id])
  end

  # パラメータからUserを取得する
  def find_user_from_params_or_render(user_id)
    user = User.find_by(id: user_id)
    if user.nil?
      flash.now[:alert] = "ユーザーはアカウントを削除しています"
      return nil
    end
    user
  end

  # パラメータからCommunityを取得する
  def find_community_from_params_or_redirect(community_id)
    community = Community.find_by(id: community_id)
    if community.nil?
      redirect_to communities_path, alert: COMMUNITY_DISBANDED_MSG
      return nil
    end
    community
  end

  # CommunityMembershipからCommunityを取得する
  def find_community_form_community_membership_or_redirect(membership)
    community = membership&.community
    # コミュニティが削除されていた場合
    if community.nil?
      redirect_to communities_path, alert: COMMUNITY_DISBANDED_MSG
      return nil
    end
    community
  end

  # ユーザーがコミュニティに参加しているか判定
  # redirectでコミュニティ詳細に返したいとき
  def redirect_if_already_approved(user, community)
    if user.approved_in?(community)
      redirect_to community_path(community), alert: ALREADY_JOINED_COMMUNITY_MSG
      return true
    end
    false
  end

  # ユーザーがコミュニティに参加しているか判定
  # renderで画面に返したいとき
  def render_if_already_approved(user, community)
    if user.approved_in?(community)
      flash.now[:alert] = ALREADY_JOINED_COMMUNITY_MSG
      return true
    end
    false
  end

  # ユーザーがコミュニティから退会しているか判定
  # renderで画面に返したいとき
  def render_if_already_withdrawn(user, community)
    unless user.approved_in?(community)
      flash.now[:alert] = ALREADY_WITHDRAWN_COMMUNITY_MSG
      return true
    end
    false
  end

  # ユーザーがコミュニティのリーダーであるか判定
  def redirect_unless_leader(user, community)
    unless user.leader_in?(community)
      redirect_to community_path(community), alert: "操作を行う権限がありません"
      return true
    end
    false
  end

  # ユーザーがコミュニティのリーダーまたはサブリーダーであるか判定
  def redirect_unless_leader_or_sub(user, community)
    unless user.leader_or_sub_in?(community)
      redirect_to community_path(community), alert: "操作を行う権限がありません"
      return true
    end
    false
  end

  # ユーザーが同じであるか判定
  def redirect_if_user_mismatch(user1, user2, community)
    if user1 != user2
      redirect_to community_path(community), alert: "不正な入力がありました"
      return true
    end
    false
  end
end
