require "rails_helper"

RSpec.describe "MachiRepos", type: :system do
  # 東京駅：東京都千代田区 latitude: 35.6812996, longitude: 139.7670658
  let(:prefecture) { create(:prefecture, id: 13, name_kanji: "東京都") }
  let(:municipality) { create(:municipality, id: 634, name_kanji: "千代田区", prefecture: prefecture) }
  let(:user) { create(:user) }
  let!(:profile) { create(:profile, user: user, prefecture: prefecture, municipality: municipality) }
  let(:machi_repo) { create(:machi_repo,
        user: user,
        title: "テスト自作",
        latitude: 35.6812996,
        longitude: 139.7670658,
        address: "東京都千代田区"
        )}

  describe "まちレポ" do
    before do
      # Google Maps API用のスタブ
      # "Geocoder result"の部分は任意の名前を付けられる
      fake_result = double("Geocoder result",
        coordinates: [ 35.6812996, 139.7670658 ],
        country_code: "JP",
        city: "千代田区",
        state: "東京都"
        )
      allow(Geocoder).to receive(:search).and_return([ fake_result ])
    end

    context "まちレポ0件" do
      it "0件用の表示" do
        login_as(user)
        # チューリアルへのリンク
        expect(page).to have_content("\"まちレポ\"を作成してみませんか？"), "チュートリアルへのリンクが表示されていません"
        # 住所
        within("#display-address") do
          expect(page).to have_content("東京都千代田区"), "住所が表示されていません"
        end
        # 周辺のホットスポット
        expect(page).to have_content("周辺のホットスポット（0件）"), "「周辺のホットスポット（0件）」が表示されていません"
        # "まち"のまちレポ一覧
        expect(page).to have_content("\"まち\"のまちレポ一覧（0件）"), "「\"まち\"のまちレポ一覧（0件）」が表示されていません"
      end
    end

    context "まちレポ1件(自作)" do
      it "通常表示" do
        machi_repo
        login_as(user)
        # チューリアルへのリンクなし
        expect(page).not_to have_content("\"まちレポ\"を作成してみませんか？"), "チュートリアルへのリンクが表示されています"
        # 住所
        within("#display-address") do
          expect(page).to have_content("東京都千代田区"), "住所が表示されていません"
        end
        # 周辺のホットスポット
        expect(page).to have_content("周辺のホットスポット（1件）"), "「周辺のホットスポット（1件）」が表示されていません"
        # "まち"のまちレポ一覧
        expect(page).to have_content("\"まち\"のまちレポ一覧（1件）"), "「\"まち\"のまちレポ一覧（1件）」が表示されていません"
        within("#machi_repos") do
          expect(page).to have_content("テスト自作"), "まちレポ一覧にカードが表示されていません"
        end
      end
    end

    context "詳細画面へ遷移" do
      it "カードから詳細画面へ" do
        machi_repo
        login_as(user)
        within("#machi_repos") do
          click_link machi_repo.title
          expect(page).to have_content(machi_repo.title), "まちレポのタイトルが表示されていません"
          expect(page).to have_current_path(machi_repo_path(machi_repo), ignore_query: true), "まちレポ詳細画面に遷移できていません"
        end
      end
    end
  end

  describe "まちレポ作成" do
    before do
      login_as(user)
      # Google Maps API用のスタブ
      fake_result = instance_double(Geocoder::Result::Base, coordinates: [ 35.6812996, 139.7670658 ])
      allow(Geocoder).to receive(:search).and_return([ fake_result ])

      visit new_machi_repo_path(user)
      expect(page).to have_current_path(new_machi_repo_path(user), ignore_query: true), "まちレポ作成画面に遷移できていません"
    end

    context "必須入力のみ入力" do
      it "成功" do
        fill_in "タイトル", with: "テスト"
        select "共有", from: "情報レベル"
        select "防犯・治安", from: "カテゴリー"
        select "エリア指定", from: "ホットスポット設定"
        select "50m", from: "エリア半径"
        click_button "登録"
        expect(page).to have_content("まちレポを作成しました"), "Flashメッセージが表示されていません"
        machi_repo = MachiRepo.find_by(title: "テスト")
        expect(page).to have_current_path(machi_repo_path(machi_repo), ignore_query: true), "まちレポ詳細画面に遷移できていません"
      end

      it "失敗" do
        # 必須入力で空になる可能性があるのは"タイトル"だけ
        select "共有", from: "情報レベル"
        select "防犯・治安", from: "カテゴリー"
        select "エリア指定", from: "ホットスポット設定"
        select "50m", from: "エリア半径"
        click_button "登録"
        expect(page).to have_content("タイトルを入力してください"), "Flashメッセージが表示されていません"
        expect(page).to have_current_path(new_machi_repo_path(user), ignore_query: true), "まちレポ作成画面に留まっていません"
      end
    end

    context "任意入力も入力" do
      it "成功(タグ)" do
        fill_in "タイトル", with: "テスト"
        select "緊急", from: "情報レベル"
        select "その他・気になること", from: "カテゴリー"
        fill_in "タグ（最大15文字 3つまで）", with: "テスト, test, 123"
        select "ピンポイント指定", from: "ホットスポット設定"
        click_button "登録"
        expect(page).to have_content("まちレポを作成しました"), "Flashメッセージが表示されていません"
        machi_repo = MachiRepo.find_by(title: "テスト")
        expect(page).to have_current_path(machi_repo_path(machi_repo), ignore_query: true), "まちレポ詳細画面に遷移できていません"
      end

      it "成功(状況説明)" do
        fill_in "タイトル", with: "テスト"
        select "緊急", from: "情報レベル"
        select "その他・気になること", from: "カテゴリー"
        fill_in "状況説明", with: "テストだよ。テストだよ。テストだよ。"
        select "ピンポイント指定", from: "ホットスポット設定"
        click_button "登録"
        expect(page).to have_content("まちレポを作成しました"), "Flashメッセージが表示されていません"
        machi_repo = MachiRepo.find_by(title: "テスト")
        expect(page).to have_current_path(machi_repo_path(machi_repo), ignore_query: true), "まちレポ詳細画面に遷移できていません"
      end

      it "成功(画像)" do
        fill_in "タイトル", with: "テスト"
        select "緊急", from: "情報レベル"
        select "その他・気になること", from: "カテゴリー"
        select "ピンポイント指定", from: "ホットスポット設定"
        attach_file "画像", Rails.root.join("spec/fixtures/sample.jpeg")
        click_button "登録"
        expect(page).to have_content("まちレポを作成しました"), "Flashメッセージが表示されていません"
        machi_repo = MachiRepo.find_by(title: "テスト")
        expect(page).to have_current_path(machi_repo_path(machi_repo), ignore_query: true), "まちレポ詳細画面に遷移できていません"
      end
    end
  end

  describe "まちレポ詳細" do
    before do
      # Google Maps API用のスタブ
      # "Geocoder result"の部分は任意の名前を付けられる
      fake_result = double("Geocoder result",
        coordinates: [ 35.6812996, 139.7670658 ],
        country_code: "JP",
        city: "千代田区",
        state: "東京都"
        )
      allow(Geocoder).to receive(:search).and_return([ fake_result ])
      machi_repo
      login_as(user)
    end

    context "自作のまちレポ" do
      before do
        # 自作のまちレポ詳細画面へ遷移
        visit machi_repo_path(machi_repo)
        expect(page).to have_content(machi_repo.title), "まちレポのタイトルが表示されていません"
        expect(page).to have_current_path(machi_repo_path(machi_repo), ignore_query: true), "まちレポ詳細画面に遷移できていません"
      end

      it "編集画面へ遷移可能" do
        expect(page).to have_selector("#machi-repo-edit"), "編集ボタンが表示されていません"
        find("#machi-repo-edit").click
        expect(page).to have_content(machi_repo.title), "まちレポ編集画面にタイトルが表示されていません"
        expect(page).to have_current_path(edit_machi_repo_path(machi_repo), ignore_query: true), "まちレポ編集画面に遷移できていません"
      end

      it "削除可能" do
        expect(page).to have_selector("#machi-repo-delete"), "削除ボタンが表示されていません"
        find("#machi-repo-delete").click
        # 確認ダイアログ表示
        expect(page).to have_selector(".modal-button.modal-ok"), "確認ダイアログのOKボタンが表示されていません"
        find(".modal-button.modal-ok").click
        expect(MachiRepo.find_by(id: machi_repo.id)).to be_nil, "まちレポが削除されていません"
        expect(page).to have_current_path(machi_repos_path, ignore_query: true), "まちレポ画面に遷移できていません"
      end
    end

    context "他作のまちレポ" do
      before do
        other_user = create(:user, :with_profile)
        others_machi_repo = create(:machi_repo, user: other_user)

        visit machi_repo_path(others_machi_repo)
        expect(page).to have_content(others_machi_repo.title), "まちレポのタイトルが表示されていません"
        expect(page).to have_current_path(machi_repo_path(others_machi_repo), ignore_query: true), "他作のまちレポ詳細画面に遷移できていません"
      end

      it "編集・削除非表示" do
        expect(page).not_to have_selector("#machi-repo-edit"), "編集ボタンが表示されてしまっています"
        expect(page).not_to have_selector("#machi-repo-delete"), "削除ボタンが表示されてしまっています"
      end
    end
  end
end
