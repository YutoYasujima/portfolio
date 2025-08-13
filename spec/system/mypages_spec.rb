require "rails_helper"

RSpec.describe "Mypages", type: :system do
  let(:prefecture) { create(:prefecture, id: 13, name_kanji: "東京都") }
  let(:municipality) { create(:municipality, id: 634, name_kanji: "千代田区", prefecture: prefecture) }
  let(:user) { create(:user) }
  let!(:profile) { create(:profile, :with_avatar,
    user: user,
    nickname: "テスト太郎",
    identifier: "1234567890",
    bio: "自己紹介のテストです。",
    prefecture: prefecture,
    municipality: municipality)
  }
  let!(:machi_repo) { create(:machi_repo,
    user: user,
    title: "テスト自作",
    latitude: 35.6812996,
    longitude: 139.7670658,
    address: "東京都千代田区")
  }

  describe "プロフィール" do
    before do
      login_as(user)
      visit profile_path(profile)
      expect(page).to have_current_path(profile_path(profile), ignore_query: true), "マイページのプロフィール画面に遷移できていません"
      expect(page).to have_content("マイページ"), "マイページが表示されていません"
    end

    it "プロフィールが表示される" do
      # アバター
      expect(page).to have_selector("img[src*='#{profile.avatar.identifier}']"), "アバターが表示されていません"
      # ニックネーム
      expect(page).to have_content(profile.nickname), "ニックネームが正しく表示されていません"
      # ユーザーID
      expect(page).to have_content(profile.identifier), "ユーザーIDが正しく表示されていません"
      # マイタウン
      expect(page).to have_content("東京都千代田区"), "マイタウンが正しく表示されていません"
      # 自己紹介
      expect(page).to have_content(profile.bio), "自己紹介が正しく表示されていません"
    end

    context "編集" do
      before do
        click_link "machi-repo-edit"
        expect(page).to have_current_path(edit_profile_path(profile), ignore_query: true), "プロフィール編集画面に遷移できていません"
        expect(page).to have_content("プロフィール編集"), "プロフィール編集が表示されていません"
      end

      it "成功" do
        # ニックネーム
        expect(find_field("profile_nickname").value).to eq(profile.nickname)
        # ユーザーID
        expect(find_field("profile_identifier").value).to eq(profile.identifier)
        # マイタウン
        expect(page).to have_select("profile_prefecture_id", selected: "東京都")
        expect(page).to have_select("profile_municipality_id", selected: "千代田区")
        # 自己紹介
        expect(find_field("profile_bio").value).to eq(profile.bio)
        # アバター
        expect(page).to have_selector("img[src*='#{profile.avatar.identifier}']"), "画像が表示されていません"

        # ニックネームだけ更新
        fill_in "profile_nickname", with: "テスト太郎更新"
        click_button "更新"

        expect(page).to have_content("テスト太郎更新"), "ニックネームが更新されていません"
        expect(page).to have_selector("#flash_messages", text: "プロフィールを更新しました")
        expect(page).to have_current_path(profile_path(profile), ignore_query: true), "マイページのプロフィール画面に遷移できていません"
      end
    end
  end

  describe "マイまちレポ" do
    before do
      login_as(user)
      visit profile_path(profile)
      expect(page).to have_current_path(profile_path(profile), ignore_query: true), "マイページのプロフィール画面に遷移できていません"
      expect(page).to have_content("マイページ"), "マイページが表示されていません"
    end

    it "自作のまちレポを表示" do
      # 他ユーザー作のまちレポを用意
      other_user = create(:user)
      other_machi_repo = create(:machi_repo,
        user: other_user,
        title: "テスト他ユーザー",
        latitude: 35.6812996,
        longitude: 139.7670658,
        address: "東京都千代田区"
      )

      click_link "my-machi-repo-link"
      expect(page).to have_content("マイまちレポ一覧"), "マイまちレポ一覧が表示されていません"
      expect(page).to have_current_path(my_machi_repos_machi_repos_path(user_id: user.id), ignore_query: false), "マイまちレポ画面に遷移できていません"

      # 自作まちレポの表示確認
      expect(page).to have_content("テスト自作"), "自作のまちレポが表示されていません"
      expect(page).to have_no_content("テスト他ユーザー"), "他ユーザーのまちレポが表示されています"
    end
  end

  describe "ブックマーク" do
    before do
      login_as(user)
      visit profile_path(profile)
      expect(page).to have_current_path(profile_path(profile), ignore_query: true), "マイページのプロフィール画面に遷移できていません"
      expect(page).to have_content("マイページ"), "マイページが表示されていません"
    end

    it "ブックマークしたまちレポを表示" do
      other_user = create(:user, :with_profile)
      other_machi_repo = create(:machi_repo,
        user: other_user,
        title: "テスト他ユーザー",
        latitude: 35.6812996,
        longitude: 139.7670658,
        address: "東京都千代田区"
      )
      # 他ユーザーが作ったまちレポをブックマーク
      create(:bookmark, user: user, machi_repo: other_machi_repo)
      # 他ユーザーがブックマーク
      create(:bookmark, user: other_user, machi_repo: machi_repo)

      click_link "bookmark-link"
      expect(page).to have_content("まちレポブックマーク一覧"), "まちレポブックマーク一覧が表示されていません"
      expect(page).to have_current_path(bookmarks_machi_repos_path, ignore_query: true), "まちレポブックマーク画面に遷移できていません"

      # ブックマークしたまちレポ表示
      expect(page).to have_content("テスト他ユーザー"), "他ユーザーのまちレポが表示されていません"
      # 他ユーザーがブックマークしたまちレポは表示しない
      expect(page).to have_no_content("テスト自作"), "他ユーザーのブックマークが表示されています"
    end
  end

  describe "フォロー" do
    before do
      login_as(user)
      visit profile_path(profile)
      expect(page).to have_current_path(profile_path(profile), ignore_query: true), "マイページのプロフィール画面に遷移できていません"
      expect(page).to have_content("マイページ"), "マイページが表示されていません"
    end

    it "フォローを表示" do
      other_user1 = create(:user, :with_profile)
      other_user2 = create(:user, :with_profile)

      # 他ユーザーをフォロー
      create(:follow, follower: user, followed: other_user1)

      click_link "following-link"
      expect(page).to have_content("フォロー一覧"), "フォロー一覧が表示されていません"
      expect(page).to have_current_path(followings_users_path, ignore_query: true), "フォロー画面に遷移できていません"

      # フォローしたユーザーを表示
      expect(page).to have_content(other_user1.profile.nickname), "フォローしたユーザーが表示されていません"
      # フォローしていないユーザーは表示しない
      expect(page).to have_no_content(other_user2.profile.nickname), "フォローしていないユーザーが表示されています"
    end
  end

  describe "コミュニティ" do
    before do
      login_as(user)
      visit profile_path(profile)
      expect(page).to have_current_path(profile_path(profile), ignore_query: true), "マイページのプロフィール画面に遷移できていません"
      expect(page).to have_content("マイページ"), "マイページが表示されていません"
    end

    it "参加中コミュニティを表示" do
      community1 = create(:community)
      membership1 = create(:community_membership,
        user: user,
        community: community1,
        status: :approved
      )
      community2 = create(:community)
      membership2 = create(:community_membership,
        user: user,
        community: community2,
        status: :requested
      )

      click_link "community-link"
      expect(page).to have_content("参加コミュニティ一覧"), "参加コミュニティ一覧が表示されていません"
      expect(page).to have_current_path(communities_users_path(user_id: user.id), ignore_query: false), "参加コミュニティ画面に遷移できていません"

      # 参加中コミュニティを表示
      expect(page).to have_content(community1.name), "参加中のコミュニティが表示されていません"
      # 参加中以外のコミュニティを表示しない
      expect(page).to have_no_content(community2.name), "参加していないコミュニティが表示されています"
    end
  end
end
