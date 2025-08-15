require "rails_helper"

RSpec.describe "Userpages", type: :system do
  let(:prefecture) { create(:prefecture, id: 13, name_kanji: "東京都") }
  let(:municipality) { create(:municipality, id: 634, name_kanji: "千代田区", prefecture: prefecture) }
  let(:user) { create(:user, :with_profile) }
  let(:other_user) { create(:user) }
  let!(:other_profile) { create(:profile, :with_avatar,
    user: other_user,
    nickname: "他ユーザー",
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
      visit profile_path(other_profile)
      expect(page).to have_current_path(profile_path(other_profile), ignore_query: true), "ユーザーページのプロフィール画面に遷移できていません"
      expect(page).to have_content("ユーザーのプロフィール"), "ユーザーページが表示されていません"
    end

    it "プロフィールが表示される" do
      # アバター
      expect(page).to have_selector("img[src*='#{other_profile.avatar.identifier}']"), "アバターが表示されていません"
      # ニックネーム
      expect(page).to have_content(other_profile.nickname), "ニックネームが正しく表示されていません"
      # ユーザーID
      expect(page).to have_content(other_profile.identifier), "ユーザーIDが正しく表示されていません"
      # マイタウン
      expect(page).to have_content("東京都千代田区"), "マイタウンが正しく表示されていません"
      # 自己紹介
      expect(page).to have_content(other_profile.bio), "自己紹介が正しく表示されていません"
    end
  end

  describe "マイまちレポ" do
    before do
      login_as(user)
      visit profile_path(other_profile)
      expect(page).to have_current_path(profile_path(other_profile), ignore_query: true), "ユーザーページのプロフィール画面に遷移できていません"
      expect(page).to have_content("ユーザーのプロフィール"), "ユーザーページが表示されていません"
    end

    it "ユーザーのまちレポを表示" do
      # ユーザーのまちレポを用意
      other_machi_repo = create(:machi_repo,
        user: other_user,
        title: "テスト他ユーザー",
        latitude: 35.6812996,
        longitude: 139.7670658,
        address: "東京都千代田区"
      )

      click_link "my-machi-repo-link"
      expect(page).to have_content("マイまちレポ一覧"), "マイまちレポ一覧が表示されていません"
      expect(page).to have_current_path(my_machi_repos_machi_repos_path(user_id: other_user.id), ignore_query: false), "マイまちレポ画面に遷移できていません"

      # ユーザーのまちレポの表示確認
      expect(page).to have_content("テスト他ユーザー"), "ユーザーのまちレポが表示されていません
      "
      expect(page).to have_no_content("テスト自作"), "自作のまちレポが表示されています"
    end
  end
  describe "コミュニティ" do
    before do
      login_as(user)
      visit profile_path(other_profile)
      expect(page).to have_current_path(profile_path(other_profile), ignore_query: true), "ユーザーページのプロフィール画面に遷移できていません"
      expect(page).to have_content("ユーザーのプロフィール"), "ユーザーページが表示されていません"
    end

    it "ユーザーが参加中のコミュニティを表示" do
      community1 = create(:community)
      membership1 = create(:community_membership,
        user: user,
        community: community1,
        status: :approved
      )
      community2 = create(:community)
      membership2 = create(:community_membership,
        user: other_user,
        community: community2,
        status: :approved
      )

      click_link "community-link"
      expect(page).to have_content("参加コミュニティ一覧"), "参加コミュニティ一覧が表示されていません"
      expect(page).to have_current_path(communities_users_path(user_id: other_user.id), ignore_query: false), "参加コミュニティ画面に遷移できていません"

      # ユーザーが参加中のコミュニティを表示
      expect(page).to have_content(community2.name), "ユーザーが参加中のコミュニティが表示されていません"
      # ユーザーが参加していないコミュニティを表示しない
      expect(page).to have_no_content(community1.name), "ユーザーが参加していないコミュニティが表示されています"
    end
  end
end
