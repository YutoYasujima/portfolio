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
end
