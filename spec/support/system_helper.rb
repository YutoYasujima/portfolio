module SystemHelper
  def login_as(user)
    visit root_path
    click_link "ログインへ"
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: user.password
    click_button "ログイン"
    expect(page).to have_current_path(machi_repos_path, ignore_query: true), "まちレポ画面に遷移できていません"
  end

  def google_login_not_profile(auth)
    visit root_path
    click_link "ログインへ"
    click_button "Google でログイン"

    # Googleログイン → ユーザー作成を待つ（最大5秒間）
    Timeout.timeout(5) do
      loop do
        break if User.find_by(email: auth.info.email).present?
        sleep 0.1
      end
    end

    expect(page).to have_current_path(new_profile_path, ignore_query: true), "プロフィール登録画面に遷移できていません"
    expect(page).to have_content("プロフィールを登録してください"), "Flashメッセージが表示されていません"
  end

  def google_login_exist_profile
    visit root_path
    click_link "ログインへ"
    click_button "Google でログイン"
    expect(page).to have_current_path(machi_repos_path, ignore_query: true), "まちレポ画面に遷移できていません"
    expect(page).to have_content("ログインしました"), "Flashメッセージが表示されていません"
  end

  # コミュニティホームページへ遷移
  def visit_community_page
    click_link "nav-community-link"
    expect(page).to have_current_path(communities_path, ignore_query: true), "コミュニティのホーム画面に遷移できていません"
    expect(page).to have_content("\"まち\"をみんなで見守ろう！"), "マイページが表示されていません"
  end

  # コミュニティホームからコミュニティ詳細へ遷移
  def open_community(community)
    visit_community_page
    click_link "community-card-#{community.id}"
    expect(page).to have_current_path(community_path(community), ignore_query: true),
      "コミュニティの詳細画面に遷移できていません"
  end

  # コミュニティのメンバーへ遷移
  def open_community_member(community)
    open_community(community)
    # メンバーアイコン
    find("#members-link").click
    expect(page).to have_current_path(members_communities_path(community_id: community.id), ignore_query: false), "コミュニティのメンバー画面に遷移できていません"
  end
  # コミュニティのスカウトへ遷移
  def open_community_scout(community)
    open_community(community)
    # スカウトアイコン
    find("#scout-link").click
    expect(page).to have_current_path(scout_communities_path(community_id: community.id), ignore_query: false), "コミュニティのスカウト画面に遷移できていません"
  end

  # コミュニティメンバーシップ作成
  def create_membership(community, status: :required, role: :general)
    create(:community_membership, user: user, community: community, status: status, role: role)
  end

  # コミュニティメンバーシップのデータ確認
  def expect_membership_status(community, status)
    expect(
      CommunityMembership.find_by(community: community, user: user, status: status)
    ).to be_present, "ステータスが#{status}になっていません"
  end
end
