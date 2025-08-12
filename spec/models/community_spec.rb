require "rails_helper"

RSpec.describe Community, type: :model do
  describe "アソシエーション" do
    it "belongs_to :prefecture" do
      assoc = Community.reflect_on_association(:prefecture)
      expect(assoc.macro).to eq :belongs_to
    end

    it "belongs_to :municipality" do
      assoc = Community.reflect_on_association(:municipality)
      expect(assoc.macro).to eq :belongs_to
    end

    it "has_many :chats" do
      assoc = Community.reflect_on_association(:chats)
      expect(assoc.macro).to eq :has_many
    end

    it "has_many :community_memberships" do
      assoc = Community.reflect_on_association(:community_memberships)
      expect(assoc.macro).to eq :has_many
    end

    it "has_many :users through community_memberships" do
      assoc = Community.reflect_on_association(:users)
      expect(assoc.macro).to eq :has_many
      expect(assoc.options[:through]).to eq :community_memberships
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(create(:community)).to be_valid
    end

    it "nameがないと無効" do
      community = build(:community, name: nil)
      expect(community).to be_invalid
      expect(community.errors[:name]).to be_present
    end

    it "nameが長すぎると無効" do
      community = build(:community, name: "a" * 21)
      expect(community).to be_invalid
      expect(community.errors[:name]).to be_present
    end

    it "同じ都道府県・市区町村でnameが重複すると無効" do
      prefecture = create(:prefecture)
      municipality = create(:municipality)
      create(:community, prefecture: prefecture, municipality: municipality, name: "TestName")

      duplicate = build(:community, prefecture: prefecture, municipality: municipality, name: "TestName")
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:name]).to include("は同じ都道府県・市区町村内で既に使われています")
    end

    it "prefectureがないと無効" do
      community = build(:community, prefecture: nil)
      expect(community).to be_invalid
      expect(community.errors[:prefecture_id]).to be_present
    end

    it "municipalityがないと無効" do
      community = build(:community, municipality: nil)
      expect(community).to be_invalid
      expect(community.errors[:municipality_id]).to be_present
    end

    it "descriptionは空でも有効" do
      community = create(:community, description: "")
      expect(community).to be_valid
    end

    it "descriptionが長すぎると無効" do
      community = build(:community, description: "a" * 501)
      expect(community).to be_invalid
      expect(community.errors[:description]).to be_present
    end
  end

  describe "icon画像アップロード機能" do
    let(:community) { create(:community) }

    it "iconは空でも有効" do
      community.icon = ""
      expect(community).to be_valid
    end

    it "iconカラムにCommunityIconUploaderがマウントされている" do
      expect(Community.uploaders[:icon]).to eq CommunityIconUploader
    end

    it "画像アップロード" do
      image_file = generate_temp_image(width: 640, height: 480)
      prefecture = create(:prefecture)
      municipality = create(:municipality)
      community = build(:community, prefecture: prefecture, municipality: municipality, icon: Rack::Test::UploadedFile.new(image_file, "image/jpeg"))

      expect(community.save).to be true
      expect(community.icon).to be_present
    ensure
      image_file.close
      image_file.unlink
    end

    context "拡張子の許可" do
      it "許可された拡張子のファイルなら有効" do
        %w[jpg jpeg png gif].each do |ext|
          file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.#{ext}"), "image/#{ext}")
          community.icon = file
          expect(community).to be_valid, "Expected .#{ext} to be valid"
        end
      end

      it "許可されていない拡張子のファイルなら無効" do
        file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.txt"), "text/plain")
        community.icon = file
        expect(community).to be_invalid
        expect(community.errors[:icon]).to be_present
      end
    end

    context "ファイルサイズの制限" do
      it "10MBを超えると無効" do
        # バリデーションで弾かれるため、アップローダークラスのprocessは動かない
        temp_file = Tempfile.new([ "large_image", ".jpeg" ])
        temp_file.write("a" * (10.megabytes + 1))
        temp_file.rewind

        file = Rack::Test::UploadedFile.new(temp_file.path, "image/jpeg")
        community.icon = file

        expect(community).to be_invalid
        expect(community.errors[:icon]).to be_present
      ensure
        temp_file.close
        temp_file.unlink
      end
    end
  end

  describe "#base" do
    it "prefecture.name_kanji と municipality.name_kanji の連結を返す" do
      prefecture = build(:prefecture, name_kanji: "東京都")
      municipality = build(:municipality, name_kanji: "新宿区")
      community = build(:community, prefecture: prefecture, municipality: municipality)

      expect(community.base).to eq "東京都新宿区"
    end
  end

  describe "#leader" do
    it "roleがleaderのcommunity_membershipのuserを返す" do
      community = create(:community)
      leader_user = create(:user)
      # leaderのmembershipを作成
      create(:community_membership, community: community, user: leader_user, role: :leader)

      expect(community.leader).to eq leader_user
    end
  end

  describe "#sub_leaders" do
    it "roleがsubのusersを返す" do
      community = create(:community)
      sub_leader_user = create(:user)
      create(:community_membership, community: community, user: sub_leader_user, role: :sub)

      expect(community.sub_leaders).to include(sub_leader_user)
    end
  end

  describe "#general_members" do
    it "approvedかつroleがgeneralのusersを返す" do
      community = create(:community)
      general_user = create(:user)
      create(:community_membership, community: community, user: general_user, role: :general, status: :approved)

      expect(community.general_members).to include(general_user)
    end
  end
end
