require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "アソシエーション" do
    it "belongs to user" do
      assoc = Profile.reflect_on_association(:user)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "belongs to prefecture" do
      assoc = Profile.reflect_on_association(:prefecture)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "belongs to municipality" do
      assoc = Profile.reflect_on_association(:municipality)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "バリデーション" do
    subject(:profile) { build(:profile, agreement: "1") }

    it "正常な入力の場合" do
      expect(profile).to be_valid
    end

    context "nickname" do
      it "nicknameがなければ無効" do
        profile.nickname = nil
        expect(profile).not_to be_valid
        expect(profile.errors[:nickname]).to be_present
      end

      it "nicknameが20文字以下なら有効" do
        profile.nickname = "a" * 20
        expect(profile).to be_valid
      end

      it "nicknameが21文字以上なら無効" do
        profile.nickname = "a" * 21
        expect(profile).not_to be_valid
        expect(profile.errors[:nickname]).to be_present
      end
    end

    context "identifier（before_validationで自動生成される）" do
      it "identifierが10文字以下なら有効" do
        profile.identifier = "a" * 10
        expect(profile).to be_valid
      end
    end

    context "bio" do
      it "bioは空でも有効" do
        profile.bio = ""
        expect(profile).to be_valid
      end

      it "bioが500文字以下なら有効" do
        profile.bio = "a" * 500
        expect(profile).to be_valid
      end

      it "bioが501文字以上なら無効" do
        profile.bio = "a" * 501
        expect(profile).not_to be_valid
        expect(profile.errors[:bio]).to be_present
      end
    end

    context "avatar" do
      it "avatarは空でも有効" do
        profile.avatar = ""
        expect(profile).to be_valid
      end

      it "avatarが許可された形式なら有効" do
        profile.avatar = "https://example.com/image.png"
        expect(profile).to be_valid
      end

      it "avatarが許可されていない形式なら無効" do
        profile.avatar = "http://example.com/image.bmp"
        expect(profile).not_to be_valid
        expect(profile.errors[:avatar]).to be_present
      end

      it "avatarが255文字以下なら有効" do
        url = "http://example.com/" + ("a" * 232) + ".jpg"
        profile.avatar = url
        expect(profile).to be_valid
      end

      it "avatarが256文字以上なら無効" do
        url = "http://example.com/" + ("a" * 241) + ".jpg"
        profile.avatar = url
        expect(profile).not_to be_valid
        expect(profile.errors[:avatar]).to be_present
      end
    end

    context "agreement" do
      it "agreementが'1'でなければ無効" do
        profile.agreement = "0"
        expect(profile).not_to be_valid
        expect(profile.errors[:agreement]).to be_present
      end
    end
  end

  describe "コールバック" do
    context "before_validation :set_unique_identifier" do
      it "作成時に自動で一意のidentifierをセットする" do
        # identifierを空にする
        profile = build(:profile, identifier: nil)
        expect(profile.identifier).to be_nil

        # before_validationでidentifierがセットされるはず
        profile.valid?

        expect(profile.identifier).to be_present
        expect(profile.identifier.length).to eq(10)
        expect(profile.identifier).to match(/\A[a-zA-Z0-9_\-]{10}\z/)
      end

      it "既存のidentifierと重複しないidentifierを生成する" do
        existing = create(:profile, identifier: "DUPLICATED")
        profile = build(:profile, identifier: nil, nickname: "other_nick", agreement: "1")

        profile.valid?

        expect(profile.identifier).to be_present
        expect(profile.identifier).not_to eq(existing.identifier)
      end
    end
  end
end
