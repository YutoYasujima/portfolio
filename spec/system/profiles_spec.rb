require 'rails_helper'

RSpec.describe "Profiles", type: :system do
  # Google認証で取得できる情報
  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        email: "test@example.com"
      }
    )
  end
  let!(:user) { create(:user,
    email: "test@example.com",
    provider: "google_oauth2",
    uid: "123456789"
  ) }

  describe "登録" do
    before do
      OmniAuth.config.mock_auth[:google_oauth2] = auth

      # 都道府県を複数作成
      osaka = create(:prefecture, name_kanji: "大阪府")
      tokyo = create(:prefecture, name_kanji: "東京都")

      # 市区町村を複数作成（例：千代田区・新宿区など）
      create(:municipality, prefecture: osaka, name_kanji: "北区")
      create(:municipality, prefecture: tokyo, name_kanji: "新宿区")
      create(:municipality, prefecture: tokyo, name_kanji: "千代田区")

      google_login_not_profile(auth)
    end

    it "成功" do
      fill_in "ニックネーム", with: "テスト太郎"
      select "東京都", from: "profile_prefecture_id"
      # Stimulusで市区町村の選択肢が動的に書き換わるのを待つ
      within "#profile_municipality_id" do
        expect(page).to have_content("千代田区")
      end
      select "千代田区", from: "profile_municipality_id"
      check "profile_agreement"
      click_button "登録"

      expect(page).to have_current_path(machi_repos_path, ignore_query: true), "まちレポ画面に遷移できていません"
      expect(Profile.where(user: user).count).to eq 1
      expect(page).to have_selector("#flash_messages", text: "プロフィールを登録しました")
    end

    it "失敗(マイタウン以外、全部未入力)" do
      click_button "登録"
      expect(page).to have_selector("#flash_messages", text: "プロフィールの登録に失敗しました")
      expect(page).to have_selector("#flash_messages", text: "ニックネームを入力してください")
      expect(page).to have_selector("#flash_messages", text: "利用規約とプライバシーポリシーに同意してください")
      expect(page).to have_current_path(new_profile_path, ignore_query: true), "プロフィール登録画面ではない画面に遷移しています"
    end
  end
end
