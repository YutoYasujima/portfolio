require "rails_helper"

RSpec.describe "UserSessions", type: :system do
  let(:user) { create(:user, :with_profile) }

  describe "ログイン" do
    describe "通常ログイン" do
      context "入力値が正常" do
        it "ログイン成功" do
          visit new_user_session_path
          fill_in "メールアドレス", with: user.email
          fill_in "パスワード", with: user.password
          click_button "ログイン"
          expect(page).to have_current_path(machi_repos_path, ignore_query: true), "まちレポ画面に遷移できていません"
          expect(page).to have_content("ログインしました。"), "Flashメッセージが表示されていません"
        end
      end

      context "パスワードが間違っている" do
        it "ログイン失敗" do
          visit new_user_session_path
          fill_in "メールアドレス", with: user.email
          fill_in "パスワード", with: "wrong password"
          click_button "ログイン"
          expect(page).to have_current_path(new_user_session_path, ignore_query: true), "ログイン画面に留まっていません"
          expect(page).to have_content("メールアドレスまたはパスワードが違います。"), "Flashメッセージが表示されていません"
        end
      end
    end

    describe "Google認証ログイン" do
      let(:auth) {
        OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          uid: "123456789",
          info: {
            email: "newuser@example.com",
            name: "新規ユーザー"
          }
        )
      }

      before do
        OmniAuth.config.mock_auth[:google_oauth2] = auth
      end

      context "ユーザー未登録" do
        it "ユーザーが登録され、ログインが成功したら、プロフィール登録画面へ" do
          visit new_user_session_path
          click_button "Google でログイン"
          expect(User.find_by(email: auth.info.email)).to be_present, "Googleログイン認証時にUserが作成されていません"
          expect(page).to have_current_path(new_profile_path, ignore_query: true), "プロフィール登録画面に遷移できていません"
          expect(page).to have_content("プロフィールを登録してください"), "Flashメッセージが表示されていません"
        end
      end

      context "ユーザー登録済み・プロフィール未登録" do
        it "ログインが成功したら、プロフィール登録画面へ" do
          google_user = create(:user,
            email: auth.info.email,
            provider: auth.provider,
            uid: auth.uid
            )

          visit new_user_session_path
          click_button "Google でログイン"
          expect(page).to have_current_path(new_profile_path, ignore_query: true), "プロフィール登録画面に遷移できていません"
          expect(page).to have_content("プロフィールを登録してください"), "Flashメッセージが表示されていません"
        end
      end

      context "ユーザー・プロフィールともに登録済み" do
        it "ログインが成功したら、まちレポ画面へ" do
          google_user = create(:user, :with_profile,
            email: auth.info.email,
            provider: auth.provider,
            uid: auth.uid
            )

          visit new_user_session_path
          click_button "Google でログイン"
          expect(page).to have_current_path(machi_repos_path, ignore_query: true), "まちレポ画面に遷移できていません"
          expect(page).to have_content("ログインしました"), "Flashメッセージが表示されていません"
        end
      end
    end
  end

  describe "ログアウト" do
    describe "通常ログイン時" do
      it "ログアウト成功" do
        login_as(user)
        find("#hamburger-menu-open").click
        click_link "ログアウト"
        expect(page).to have_current_path(root_path, ignore_query: true), "トップ画面に戻っていません"
        expect(page).to have_content("ログアウトしました。"), "ログアウト成功メッセージが表示されていません"
      end
    end

    describe "Google認証ログイン時" do
      let(:auth) {
        OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          uid: "123456789",
          info: {
            email: "newuser@example.com",
            name: "新規ユーザー"
          }
        )
      }

      before do
        OmniAuth.config.mock_auth[:google_oauth2] = auth
      end

      context "プロフィール登録画面" do
        it "ログアウト成功" do
          google_login_not_profile(auth)
          click_link "ログアウト"
          expect(page).to have_current_path(root_path, ignore_query: true), "トップ画面に戻っていません"
          expect(page).to have_content("ログアウトしました。"), "ログアウト成功メッセージが表示されていません"
        end
      end

      context "まちレポ画面" do
        it "ログアウト成功" do
          google_user = create(:user, :with_profile,
            email: auth.info.email,
            provider: auth.provider,
            uid: auth.uid
            )
          google_login_exist_profile()
          find("#hamburger-menu-open").click
          click_link "ログアウト"
          expect(page).to have_current_path(root_path, ignore_query: true), "トップ画面に戻っていません"
          expect(page).to have_content("ログアウトしました。"), "ログアウト成功メッセージが表示されていません"
        end
      end
    end
  end
end
