require 'rails_helper'

RSpec.describe User, type: :model do
  describe "バリデーション" do
    subject(:user) { build(:user, agreement: "1") }

    context "正常な入力の場合" do
      it { is_expected.to be_valid }
    end

    context "email" do
      it "emailがないと無効" do
        user.email = nil
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it "emailが重複していると無効" do
        create(:user, email: "duplicate@example.com")
        user.email = "duplicate@example.com"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it "emailの形式が不正だと無効" do
        user.email = "invalid_email"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end
    end

    context "password" do
      it "passwordが空だと無効" do
        user.password = ""
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "passwordが6文字未満だと無効" do
        user.password = "12345"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it "passwordが6文字以上なら有効" do
        user.password = "123456"
        subject.password_confirmation = "123456"
        expect(user).to be_valid
      end
    end

    context "password_confirm" do
      it "password_confirmationが一致すれば有効" do
        user.password = "pass123"
        user.password_confirmation = "pass123"
        expect(user).to be_valid
      end

      it "password_confirmationと一致しないと無効" do
        user.password = "pass123"
        user.password_confirmation = "mismatch"
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to be_present
      end
    end

    context "agreement（同意）" do
      it "agreementが'0'だと無効" do
        user.agreement = "0"
        expect(user).not_to be_valid
        expect(user.errors[:agreement]).to be_present
      end
    end
  end

  describe ".from_omniauth" do
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

    it "新しいユーザーを作成する" do
      expect {
        user = User.from_omniauth(auth)
        expect(user).to be_persisted
        expect(user.email).to eq("test@example.com")
        expect(user.provider).to eq("google_oauth2")
        expect(user.uid).to eq("123456789")
        expect(user.confirmed_at).not_to be_nil
      }.to change(User, :count).by(1)
    end

    it "既存ユーザーを返す" do
      user = User.from_omniauth(auth)
      same_user = User.from_omniauth(auth)
      expect(same_user).to eq(user)
    end
  end

  describe "#mytown_address" do
    it "prefectureとmunicipalityのname_kanjiを結合して返す" do
      prefecture = create(:prefecture, name_kanji: "東京都")
      municipality = create(:municipality, name_kanji: "渋谷区", prefecture: prefecture)
      profile = build(:profile, prefecture: prefecture, municipality: municipality)
      user = build(:user, agreement: "1", profile: profile)

      expect(user.mytown_address).to eq("東京都渋谷区")
    end
  end
end
