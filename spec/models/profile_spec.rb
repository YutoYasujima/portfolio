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
    end

    describe "avatar画像アップロード機能" do
    it "avatarカラムにMachiRepoImageUploaderがマウントされている" do
      expect(Profile.uploaders[:avatar]).to eq ProfileAvatarUploader
    end

    it "画像アップロード" do
      image_file = generate_temp_image(width: 640, height: 480)
      profile = build(:profile, avatar: Rack::Test::UploadedFile.new(image_file, "image/jpeg"))

      expect(profile.save).to be true
      expect(profile.avatar).to be_present
      expect(profile.avatar.medium).to be_present
      expect(profile.avatar.thumb).to be_present
    ensure
      image_file.close
      image_file.unlink
    end

    context "拡張子の許可" do
      it "許可された拡張子のファイルなら有効" do
        %w[jpg jpeg png gif].each do |ext|
          file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.#{ext}"), "image/#{ext}")
          profile.avatar = file
          expect(profile).to be_valid, "Expected .#{ext} to be valid"
        end
      end

      it "許可されていない拡張子のファイルなら無効" do
        file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.txt"), "text/plain")
        profile.avatar = file
        expect(profile).to be_invalid
        expect(profile.errors[:avatar]).to be_present
      end
    end

    context "ファイルサイズの制限" do
      it "10MBを超えると無効" do
        # バリデーションで弾かれるため、アップローダークラスのprocessは動かない
        temp_file = Tempfile.new([ "large_image", ".jpeg" ])
        temp_file.write("a" * (10.megabytes + 1))
        temp_file.rewind

        file = Rack::Test::UploadedFile.new(temp_file.path, "image/jpeg")
        profile.avatar = file

        expect(profile).to be_invalid
        expect(profile.errors[:avatar]).to be_present
      ensure
        temp_file.close
        temp_file.unlink
      end
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
