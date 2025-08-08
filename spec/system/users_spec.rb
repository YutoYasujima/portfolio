require "rails_helper"

RSpec.describe "Users", type: :system do
  describe "新規作成" do
    context "登録" do
      before do
        # 都道府県を複数作成
        osaka = create(:prefecture, name_kanji: "大阪府")
        tokyo = create(:prefecture, name_kanji: "東京都")

        # 市区町村を複数作成（例：千代田区・新宿区など）
        create(:municipality, prefecture: osaka, name_kanji: "北区")
        create(:municipality, prefecture: tokyo, name_kanji: "新宿区")
        create(:municipality, prefecture: tokyo, name_kanji: "千代田区")

        visit new_user_session_path
        click_link "新規登録"
        expect(page).to have_current_path(new_user_registration_path, ignore_query: true), "ユーザー登録画面に遷移できていません"
      end

      it "成功", js: true do
        fill_in "ニックネーム", with: "テスト太郎"
        select "東京都", from: "user_profile_attributes_prefecture_id"
        # Stimulusで市区町村の選択肢が動的に書き換わるのを待つ
        expect(page).to have_select("user_profile_attributes_municipality_id", with_options: [ "千代田区" ])
        select "千代田区", from: "user_profile_attributes_municipality_id"
        fill_in "メールアドレス", with: "sample@example.com"
        fill_in "パスワード", with: "123456"
        fill_in "パスワード（確認用）", with: "123456"
        check "user_agreement"
        click_button "登録"

        # 成功フラッシュを待つ（非同期処理の完了保証）
        expect(page).to have_selector("#flash_messages", text: "本人確認用のメールを送信しました。", wait: 10)

        # DBから最新ユーザー取得
        user = User.order(created_at: :desc).first
        # userと関連するprofileが作成されているか確認
        expect(user.profile.nickname).to eq "テスト太郎"

        expect(page).to have_current_path(root_path, ignore_query: true), "トップ画面に遷移できていません"

        # 確認メール
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to include("sample@example.com")

        # HTMLの確認リンクを抽出（hrefから）
        html = mail.body.encoded
        # hrefから確認URLを抽出（localhost:3000が含まれている）
        confirmation_url = html[/href="([^"]*\/users\/confirmation\?confirmation_token=[^"]+)"/, 1]
        expect(confirmation_url).to be_present, "確認URLが見つかりません"

        # localhost:3000 を Capybara の起動URLに置換する
        test_host = Capybara.current_session.server.base_url
        confirmation_uri = URI.parse(confirmation_url)

        # 置換後のURLを組み立ててアクセス
        confirmation_url = "#{test_host}#{confirmation_uri.path}?#{confirmation_uri.query}"

        visit confirmation_url

        expect(page).to have_selector("#flash_messages", text: "メールアドレスが確認できました。")
        expect(page).to have_current_path(machi_repos_path, ignore_query: true), "まちレポ画面に遷移できていません"
      end

      it "失敗(マイタウン以外、全部未入力)", js: true do
        click_button "登録"
        expect(page).to have_selector("#flash_messages", text: "メールアドレスを入力してください")
        expect(page).to have_selector("#flash_messages", text: "パスワードを入力してください")
        expect(page).to have_selector("#flash_messages", text: "ニックネームを入力してください")
        expect(page).to have_selector("#flash_messages", text: "利用規約とプライバシーポリシーに同意してください")
        expect(page).to have_current_path(new_user_registration_path, ignore_query: true), "ユーザー登録画面ではない画面に遷移しています"
      end
    end
  end
end
