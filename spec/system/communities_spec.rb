require "rails_helper"

RSpec.describe "Communities", type: :system do
  let(:prefecture) { create(:prefecture, id: 13, name_kanji: "東京都") }
  let(:municipality) { create(:municipality, id: 634, name_kanji: "千代田区", prefecture: prefecture) }
  let(:other_prefecture) { create(:prefecture,  name_kanji: "大阪府") }
  let(:other_municipality) { create(:municipality,  name_kanji: "北区", prefecture: other_prefecture) }
  let(:user) { create(:user) }
  let!(:profile) { create(:profile,
    user: user,
    nickname: "テスト太郎",
    identifier: "1234567890",
    prefecture: prefecture,
    municipality: municipality)
  }
  let!(:community) { create(:community, :with_icon,
    name: "テストコミュニティ",
    description: "コミュニティの説明です。",
    prefecture: prefecture,
    municipality: municipality)
  }
  let!(:membership) { create(:community_membership,
    user: user,
    community: community,
    status: :approved,
    role: :leader)
  }

  before do
    login_as(user)
  end

  describe "ホーム" do
    it "ホーム画面にコミュニティが表示される" do
      visit_community_page
      expect(page).to have_content(community.name), "コミュニティホーム画面にコミュニティが表示されていません"
    end
  end

  describe "詳細" do
    it "詳細が表示される" do
      open_community(community)
      # アイコン
      expect(page).to have_selector("img[src*='#{community.icon.identifier}']"), "アイコンが表示されていません"
      # コミュニティ名
      expect(page).to have_content(community.name), "コミュニティ名が表示されていません"
      # 活動拠点
      expect(page).to have_content("東京都千代田区"), "活動拠点が正しく表示されていません"
      # 自己紹介
      expect(page).to have_content(community.description), "コミュニティ紹介が正しく表示されていません"
    end

    context "役職毎の操作" do
      it "リーダーは編集・解散ボタンが表示される" do
        open_community(community)
        # 編集ボタン
        expect(page).to have_selector("#community-edit"), "編集ボタンが表示されていません"
        # 解散ボタン
        expect(page).to have_selector("#community-delete"), "解散ボタンが表示されていません"
      end

      it "サブリーダーは編集ボタンのみ表示される" do
        subleader_communities = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(subleader_communities, status: :approved, role: :sub)
        open_community(subleader_communities)
        # 編集ボタン
        expect(page).to have_selector("#community-edit"), "編集ボタンが表示されていません"
        # 解散ボタン
        expect(page).to have_no_selector("#community-delete"), "解散ボタンが表示されています"
      end

      it "一般メンバーは編集・解散ボタンが表示されない" do
        general_communities = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(general_communities, status: :approved, role: :general)
        open_community(general_communities)
        # 編集ボタン
        expect(page).to have_no_selector("#community-edit"), "編集ボタンが表示されています"
        # 解散ボタン
        expect(page).to have_no_selector("#community-delete"), "解散ボタンが表示されています"
      end

      it "リーダーは解散ができる" do
        open_community(community)
        # 解散ボタン
        find("#community-delete").click
        # 確認ダイアログ表示
        expect(page).to have_selector(".modal-button.modal-ok"), "確認ダイアログのOKボタンが表示されていません"
        find(".modal-button.modal-ok").click
        # 遷移完了を確認
        expect(page).to have_current_path(communities_path, ignore_query: true), "コミュニティのホーム画面に遷移できていません"
        expect(Community.find_by(id: community.id)).to be_nil, "コミュニティが解散できていません"
      end
    end

    context "参加希望" do
      it "未参加ユーザーは参加希望できる（membershipあり）" do
        new_community = create(:community, prefecture: prefecture, municipality: municipality)
        open_community(new_community)
        # 参加希望ボタン
        find("#join-button").click
        expect(page).to have_selector("#flash_messages", text: "参加をリクエストしました")
        expect_membership_status(new_community, :requested)
      end

      it "未参加ユーザーは参加希望できる（membershipあり）" do
        new_community = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(new_community, status: :cancelled, role: :general)
        open_community(new_community)
        # 参加希望ボタン
        find("#join-button").click
        expect(page).to have_selector("#flash_messages", text: "参加をリクエストしました")
        expect_membership_status(new_community, :requested)
      end

      it "参加希望中はキャンセルできる" do
        new_community = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(new_community, status: :requested, role: :general)
        open_community(new_community)
        # キャンセルボタン
        find("#join-cancel-button").click
        expect(page).to have_selector("#flash_messages", text: "参加希望を取り消しました")
        expect_membership_status(new_community, :cancelled)
      end
    end

    context "スカウト" do
      it "スカウト中はよろしく・ことわるボタンが表示される" do
        new_community = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(new_community, status: :invited)
        open_community(new_community)
        # よろしくボタン
        expect(page).to have_selector("#invited-button"), "よろしくボタンが表示されていません"
        # ことわるボタン
        expect(page).to have_selector("#reject-invited-button"), "ことわるボタンが表示されていません"
      end

      it "スカウトを承認できる" do
        new_community = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(new_community, status: :invited, role: :general)
        open_community(new_community)
        # よろしくボタン
        find("#invited-button").click
        expect(page).to have_selector("#flash_messages", text: "コミュニティに参加しました")
        expect_membership_status(new_community, :approved)
      end

      it "スカウトを断れる" do
        new_community = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(new_community, status: :invited, role: :general)
        open_community(new_community)
        # ことわるボタン
        find("#reject-invited-button").click
        expect(page).to have_selector("#flash_messages", text: "参加を断りました")
        expect_membership_status(new_community, :rejected)
      end
    end
  end

  describe "編集" do
    it "成功" do
      open_community(community)
      # 編集ボタン
      find("#community-edit").click
      expect(page).to have_current_path(edit_community_path(community), ignore_query: true), "コミュニティ編集画面に遷移できていません"
      expect(page).to have_content("コミュニティ編集"), "コミュニティ編集が表示されていません"
      # コミュニティ名
      expect(find_field("community_name").value).to eq(community.name)
      # 活動拠点
      expect(page).to have_select("community_prefecture_id", selected: "東京都")
      expect(page).to have_select("community_municipality_id", selected: "千代田区")
      # コミュニティ紹介
      expect(find_field("community_description").value).to eq(community.description)
      # アイコン
      expect(page).to have_selector("img[src*='#{community.icon.identifier}']"), "画像が表示されていません"

      # コミュニティ名だけ更新
      fill_in "community_name", with: "コミュニティ更新"
      click_button "更新"

      expect(page).to have_content("コミュニティ更新"), "コミュニティ名が更新されていません"
      expect(page).to have_selector("#flash_messages", text: "コミュニティ情報を更新しました")
      expect(page).to have_current_path(community_path(community), ignore_query: true), "コミュニティの詳細画面に遷移できていません"
    end
  end

  describe "チャット" do
    let!(:message_chat) { create(:chat, chatable: community, user: user, message: "こんにちは", image: nil) }
    let!(:image_chat) { create(:chat, :with_image, chatable: community, user: user, message: nil) }

    before do
      open_community(community)
      # チャットアイコン
      find("#chat-link").click
      expect(page).to have_current_path(community_chats_path(community), ignore_query: true), "コミュニティのチャット画面に遷移できていません"
    end

    it "チャット初期表示" do
      expect(page).to have_content("こんにちは"), "メッセージが表示されていません"
      expect(page).to have_selector("img[src*='#{image_chat.image.identifier}']"), "画像が表示されていません"
    end
  end

  describe "メンバー" do
    context "リーダー" do
      let!(:subleader) { create(:user) }
      let!(:subleader_profile) { create(:profile, user: subleader, nickname: "サブリーダー") }
      let!(:general) { create(:user) }
      let!(:general_profile) { create(:profile, user: general, nickname: "一般メンバー") }

      before do
        create(:community_membership, community: community, user: subleader, status: :approved, role: :sub)
        create(:community_membership, community: community, user: general, status: :approved, role: :general)
        open_community_member(community)
      end

      it "役職変更ボタンが表示されている" do
        expect(find("#leader")).to have_content(user.profile.nickname), "リーダーが表示されていません"
        expect(find("#sub-leaders")).to have_content(subleader.profile.nickname), "サブリーダーが表示されていません"
        expect(page).to have_selector("#user-card-#{subleader.id} .promote-leader-buttons"), "リーダーにするボタンが表示されていません"
        expect(page).to have_selector("#user-card-#{subleader.id} .demote-general-buttons"), "メンバーにするボタンが表示されていません"
        expect(find("#members")).to have_content(general.profile.nickname), "一般メンバーが表示されていません"
        expect(page).to have_selector("#user-card-#{general.id} .promote-subleader-buttons"), "サブリーダーにするボタンが表示されていません"
        expect(page).to have_selector("#user-card-#{general.id} .reject-community-buttons"), "退会してもらうボタンが表示されていません"
      end

      it "リーダーにするを実行" do
        find("#user-card-#{subleader.id} .promote-leader-buttons").click
        # 確認ダイアログ表示
        expect(page).to have_selector(".modal-button.modal-ok"), "確認ダイアログのOKボタンが表示されていません"
        find(".modal-button.modal-ok").click

        expect(page).to have_selector("#flash_messages", text: "リーダーを交代しました")
        expect(find("#leader")).to have_no_content(user.profile.nickname), "元リーダーがリーダー欄に残っています"
        expect(find("#leader")).to have_content(subleader.profile.nickname), "元サブリーダーがリーダー欄に移動していません"
        expect(find("#sub-leaders")).to have_no_content(subleader.profile.nickname), "元サブリーダーがサブリーダー欄に残っています"
        expect(find("#sub-leaders")).to have_content(user.profile.nickname), "元リーダーがサブリーダー欄に移動していません"
        expect(CommunityMembership.find_by(community: community, user: user, role: :sub)).to be_present, "元リーダーのメンバーシップがsubになっていません"
        expect(CommunityMembership.find_by(community: community, user: subleader, role: :leader)).to be_present, "元サブリーダーのメンバーシップがleaderになっていません"
      end

      it "メンバーにするを実行" do
        find("#user-card-#{subleader.id} .demote-general-buttons").click

        expect(page).to have_selector("#flash_messages", text: "役職を変更しました")
        expect(find("#sub-leaders")).to have_no_content(subleader.profile.nickname), "元サブリーダーがサブリーダー欄に残っています"
        expect(find("#members")).to have_content(subleader.profile.nickname), "元サブリーダーがメンバー欄に移動していません"
        expect(CommunityMembership.find_by(community: community, user: subleader, role: :general)).to be_present, "元サブリーダーのメンバーシップがgeneralになっていません"
      end

      it "サブリーダーにするを実行" do
        find("#user-card-#{general.id} .promote-subleader-buttons").click

        expect(page).to have_selector("#flash_messages", text: "役職を変更しました")
        expect(find("#members")).to have_no_content(general.profile.nickname), "元メンバーがメンバー欄に残っています"
        expect(find("#sub-leaders")).to have_content(general.profile.nickname), "元メンバーがサブリーダー欄に移動していません"
        expect(CommunityMembership.find_by(community: community, user: general, role: :sub)).to be_present, "元メンバーのメンバーシップがsubになっていません"
      end

      it "退会してもらうを実行" do
        find("#user-card-#{general.id} .reject-community-buttons").click
        # 確認ダイアログ表示
        expect(page).to have_selector(".modal-button.modal-ok"), "確認ダイアログのOKボタンが表示されていません"
        find(".modal-button.modal-ok").click

        expect(page).to have_selector("#flash_messages", text: "\"#{general.profile.nickname}\"さんに退会してもらいました")
        expect(find("#members")).to have_no_content(general.profile.nickname), "元メンバーがメンバー欄に残っています"
        expect(CommunityMembership.find_by(community: community, user: general, status: :kicked, role: :general)).to be_present, "元メンバーのメンバーシップがkickedになっていません"
      end
    end

    context "リーダー以外" do
      let(:other_community) { create(:community, prefecture: prefecture, municipality: municipality) }
      let(:leader) { create(:user, :with_profile) }
      let(:subleader) { create(:user, :with_profile) }
      let(:general) { create(:user, :with_profile) }

      before do
        create(:community_membership, community: other_community, user: leader, status: :approved, role: :leader)
        create(:community_membership, community: other_community, user: subleader, status: :approved, role: :sub)
        create(:community_membership, community: other_community, user: general, status: :approved, role: :general)
      end

      it "サブリーダーなら役職変更ボタンが表示されない" do
        create_membership(other_community, status: :approved, role: :sub)
        open_community(other_community)
        open_community_member(other_community)

        expect(find("#leader")).to have_content(leader.profile.nickname), "リーダーが表示されていません"
        expect(find("#sub-leaders")).to have_content(subleader.profile.nickname), "サブリーダーが表示されていません"
        expect(page).to have_no_selector("#user-card-#{subleader.id} .promote-leader-buttons"), "リーダーにするボタンが表示されています"
        expect(page).to have_no_selector("#user-card-#{subleader.id} .demote-general-buttons"), "メンバーにするボタンが表示されていすす"
        expect(find("#members")).to have_content(general.profile.nickname), "一般メンバーが表示されていません"
        expect(page).to have_no_selector("#user-card-#{general.id} .promote-subleader-buttons"), "サブリーダーにするボタンが表示されています"
        expect(page).to have_no_selector("#user-card-#{general.id} .reject-community-buttons"), "退会してもらうボタンが表示されています"
      end

      it "一般メンバーなら役職変更ボタンが表示されない" do
        create_membership(other_community, status: :approved, role: :general)
        open_community(other_community)
        open_community_member(other_community)

        expect(find("#leader")).to have_content(leader.profile.nickname), "リーダーが表示されていません"
        expect(find("#sub-leaders")).to have_content(subleader.profile.nickname), "サブリーダーが表示されていません"
        expect(page).to have_no_selector("#user-card-#{subleader.id} .promote-leader-buttons"), "リーダーにするボタンが表示されています"
        expect(page).to have_no_selector("#user-card-#{subleader.id} .demote-general-buttons"), "メンバーにするボタンが表示されていすす"
        expect(find("#members")).to have_content(general.profile.nickname), "一般メンバーが表示されていません"
        expect(page).to have_no_selector("#user-card-#{general.id} .promote-subleader-buttons"), "サブリーダーにするボタンが表示されています"
        expect(page).to have_no_selector("#user-card-#{general.id} .reject-community-buttons"), "退会してもらうボタンが表示されています"
      end
    end
  end

  describe "スカウト" do
    let!(:other_user) { create(:user) }
    let!(:other_profile) { create(:profile, user: other_user, nickname: "ユーザーA", prefecture: prefecture, municipality: municipality) }

    context "表示" do
      it "参加希望ユーザーが表示される" do
        other_requested_membership = create(:community_membership, community: community, user: other_user, status: :requested, role: :general)
        open_community_scout(community)

        expect(find("#requested-user-cards")).to have_content(other_user.profile.nickname), "参加希望ユーザーが表示されていません"
      end

      it "スカウト中ユーザーが表示される" do
        other_invited_membership = create(:community_membership, community: community, user: other_user, status: :invited, role: :general)

        open_community_scout(community)
        expect(find("#inviting-user-cards")).to have_content(other_user.profile.nickname), "スカウト中ユーザーが表示されていません"
      end

      it "スカウト対象が表示される" do
        other_area_user = create(:user)
        other_area_profile = create(:profile, user: other_area_user, nickname: "ユーザーB", prefecture: other_prefecture, municipality: other_municipality)
        open_community_scout(community)

        expect(find("#candidate-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"
        expect(find("#candidate-user-cards")).to have_no_content(other_area_user.profile.nickname), "非スカウト対象ユーザーが表示されています"
      end
    end

    context "スカウト実行" do
      it "リーダーはスカウトできる(対象のcommunity_membershipなし)" do
        open_community_scout(community)
        expect(find("#candidate-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"

        # スカウトボタンクリック
        find("#candidate-user-#{other_user.id} .invite-buttons").click
        expect(page).to have_selector("#flash_messages", text: "スカウトしました")
        expect(find("#candidate-user-cards")).to have_no_content(other_user.profile.nickname), "対象ユーザーがスカウトする一覧に表示されています"
        expect(find("#inviting-user-cards")).to have_content(other_user.profile.nickname), "対象ユーザーがスカウト中一覧に表示されていません"
        expect(page).to have_selector("#inviting-user-cards .invite-cancel-buttons"), "スカウトキャンセルボタンが表示されていません"
        expect(CommunityMembership.find_by(community: community, user: other_user, status: :invited)).to be_present, "スカウトできていません"
      end

      it "リーダーはスカウトできる(対象のcommunity_membershipあり)" do
        create(:community_membership, community: community, user: other_user, status: :cancelled, role: :general)
        open_community_scout(community)
        expect(find("#candidate-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"

        # スカウトボタンクリック
        find("#candidate-user-#{other_user.id} .invite-buttons").click
        expect(page).to have_selector("#flash_messages", text: "スカウトしました")
        expect(find("#candidate-user-cards")).to have_no_content(other_user.profile.nickname), "対象ユーザーがスカウトする一覧に表示されています"
        expect(find("#inviting-user-cards")).to have_content(other_user.profile.nickname), "対象ユーザーがスカウト中一覧に表示されていません"
        expect(page).to have_selector("#inviting-user-cards .invite-cancel-buttons"), "スカウトキャンセルボタンが表示されていません"
        expect(CommunityMembership.find_by(community: community, user: other_user, status: :invited)).to be_present, "スカウトできていません"
      end

      it "サブリーダーはスカウトできる" do
        subleader_communities = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(subleader_communities, status: :approved, role: :sub)
        open_community(subleader_communities)
        open_community_scout(subleader_communities)
        expect(find("#candidate-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"

        # スカウトボタンクリック
        find("#candidate-user-#{other_user.id} .invite-buttons").click
        expect(page).to have_selector("#flash_messages", text: "スカウトしました")
        expect(find("#candidate-user-cards")).to have_no_content(other_user.profile.nickname), "対象ユーザーがスカウトする一覧に表示されています"
        expect(find("#inviting-user-cards")).to have_content(other_user.profile.nickname), "対象ユーザーがスカウト中一覧に表示されていません"
        expect(page).to have_selector("#inviting-user-cards .invite-cancel-buttons"), "スカウトキャンセルボタンが表示されていません"
        expect(CommunityMembership.find_by(community: subleader_communities, user: other_user, status: :invited)).to be_present, "スカウトできていません"
      end

      it "一般メンバーはスカウトできない" do
        general_communities = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(general_communities, status: :approved, role: :general)
        open_community(general_communities)
        open_community_scout(general_communities)
        expect(find("#candidate-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"

        expect(page).to have_no_selector("#candidate-user-#{other_user.id} .invite-buttons"), "スカウトボタンが表示されています"
      end
    end

    context "スカウトキャンセル" do
      it "リーダーはスカウトキャンセルできる" do
        create(:community_membership, community: community, user: other_user, status: :invited, role: :general)
        open_community_scout(community)
        expect(find("#inviting-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"

        find("#candidate-user-#{other_user.id} .invite-cancel-buttons").click
        expect(page).to have_selector("#flash_messages", text: "スカウトを取り消しました")
        expect(find("#inviting-user-cards")).to have_no_content(other_user.profile.nickname), "対象ユーザーがスカウト中一覧に表示されています"
        expect(find("#candidate-user-cards")).to have_content(other_user.profile.nickname), "対象ユーザーがスカウトする一覧に表示されていません"
        expect(page).to have_selector("#candidate-user-cards .invite-buttons"), "スカウトボタンが表示されていません"
        expect(CommunityMembership.find_by(community: community, user: other_user, status: :cancelled)).to be_present, "スカウトキャンセルできていません"
      end

      it "サブリーダーはスカウトキャンセルできる" do
        subleader_communities = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(subleader_communities, status: :approved, role: :sub)
        open_community(subleader_communities)
        create(:community_membership, community: subleader_communities, user: other_user, status: :invited, role: :general)
        open_community_scout(subleader_communities)
        expect(find("#inviting-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"

        find("#candidate-user-#{other_user.id} .invite-cancel-buttons").click
        expect(page).to have_selector("#flash_messages", text: "スカウトを取り消しました")
        expect(find("#inviting-user-cards")).to have_no_content(other_user.profile.nickname), "対象ユーザーがスカウト中一覧に表示されています"
        expect(find("#candidate-user-cards")).to have_content(other_user.profile.nickname), "対象ユーザーがスカウトする一覧に表示されていません"
        expect(page).to have_selector("#candidate-user-cards .invite-buttons"), "スカウトボタンが表示されていません"
        expect(CommunityMembership.find_by(community: subleader_communities, user: other_user, status: :cancelled)).to be_present, "スカウトキャンセルできていません"
      end

      it "一般ユーザーはスカウトキャンセルできない" do
        general_communities = create(:community, prefecture: prefecture, municipality: municipality)
        create_membership(general_communities, status: :approved, role: :general)
        open_community(general_communities)
        create(:community_membership, community: general_communities, user: other_user, status: :invited, role: :general)
        open_community_scout(general_communities)
        expect(find("#inviting-user-cards")).to have_content(other_user.profile.nickname), "スカウト対象ユーザーが表示されていません"

        expect(page).to have_no_selector("#candidate-user-#{other_user.id} .invite-cancel-buttons"), "スカウトキャンセルボタンが表示されています"
      end
    end
  end

  describe "退会" do
    it "退会する" do
      subleader_communities = create(:community, prefecture: prefecture, municipality: municipality)
      create_membership(subleader_communities, status: :approved, role: :sub)
      open_community(subleader_communities)

      find("#community-withdraw").click
      # 確認ダイアログ表示
      expect(page).to have_selector(".modal-button.modal-ok"), "確認ダイアログのOKボタンが表示されていません"
      find(".modal-button.modal-ok").click
      expect(page).to have_selector("#flash_messages", text: "退会しました")
      expect(CommunityMembership.find_by(community: subleader_communities, user: user, status: :withdrawn, role: :general)).to be_present, "自主退会できていません"
    end

    it "リーダーは退会できない" do
      open_community(community)
      find("#community-withdraw").click
      # 確認ダイアログ表示
      expect(page).to have_selector(".modal-button.modal-ok"), "確認ダイアログのOKボタンが表示されていません"
      find(".modal-button.modal-ok").click

      expect(page).to have_selector("#flash_messages", text: "リーダーは退会できません")
      expect(CommunityMembership.find_by(community: community, user: user, status: :withdrawn, role: :general)).to be_nil, "自主退会できています"
    end
  end
end
