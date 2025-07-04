require "rails_helper"

RSpec.describe MachiRepo, type: :model do
  subject(:machi_repo) { build(:machi_repo) }

  describe "アソシエーション" do
    context "静的なアソシエーション定義" do
      it "belongs_to :user" do
        assoc = MachiRepo.reflect_on_association(:user)
        expect(assoc.macro).to eq(:belongs_to)
      end

      it "has_many :machi_repo_tags (dependent: :destroy)" do
        assoc = MachiRepo.reflect_on_association(:machi_repo_tags)
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.options[:dependent]).to eq(:destroy)
      end

      it "has_many :chats (as chatable, dependent: :destroy)" do
        assoc = MachiRepo.reflect_on_association(:chats)
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.options[:as]).to eq(:chatable)
        expect(assoc.options[:dependent]).to eq(:destroy)
      end

      it "has_many :tags through :machi_repo_tags" do
        assoc = MachiRepo.reflect_on_association(:tags)
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.options[:through]).to eq(:machi_repo_tags)
      end
    end

    context "動作によるアソシエーション確認" do
      let!(:repo) { create(:machi_repo) }

      it "関連する machi_repo_tags を削除する" do
        repo.tag_names = "test"
        repo.save!
        expect(MachiRepoTag.count).to be > 0
        expect {
          repo.destroy
        }.to change { MachiRepoTag.count }.by(-1)
      end

      it "関連する chats を削除する" do
        create(:chat, chatable: repo)
        expect { repo.destroy }.to change { Chat.count }.by(-1)
      end

      it "tags を中間テーブルを通じて持つ" do
        tag = Tag.create!(name: "災害")
        repo.tags << tag
        # 上記で保存されているが念のため
        repo.save!
        # DBから最新のrepoを読み込み直す
        repo.reload
        expect(repo.tags).to include(tag)
      end
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(machi_repo).to be_valid
    end

    context "title" do
      it "タイトルが必須" do
        machi_repo.title = ""
        expect(machi_repo).to be_invalid
        expect(machi_repo.errors[:title]).to be_present
      end

      it "タイトルが30文字以内は有効" do
        machi_repo.title = "あ" * 30
        expect(machi_repo).to be_valid
      end

      it "タイトルが31文字以上は無効" do
        machi_repo.title = "あ" * 31
        expect(machi_repo).to be_invalid
        expect(machi_repo.errors[:title]).to be_present
      end
    end

    context "latitude" do
      it "緯度が必須" do
        machi_repo.latitude = nil
        expect(machi_repo).to be_invalid
        expect(machi_repo.errors[:latitude]).to be_present
      end

      it "緯度が-90〜90の範囲内は有効" do
        [-90, 90].each do |value|
          machi_repo.latitude = value
          expect(machi_repo).to be_valid
        end
      end

      it "緯度が-90〜90の範囲外は無効" do
        [-91, 91].each do |value|
          machi_repo.latitude = value
          expect(machi_repo).to be_invalid
          expect(machi_repo.errors[:latitude]).to be_present
        end
      end
    end

    context "longitude" do
      it "経度が必須" do
        machi_repo.longitude = nil
        expect(machi_repo).to be_invalid
        expect(machi_repo.errors[:longitude]).to be_present
      end

      it "経度が-180〜180の範囲内は有効" do
        [-180, 180].each do |value|
          machi_repo.longitude = value
          expect(machi_repo).to be_valid
        end
      end

      it "経度が-180〜180の範囲外は無効" do
        [-181, 181].each do |value|
          machi_repo.longitude = value
          expect(machi_repo).to be_invalid
          expect(machi_repo.errors[:longitude]).to be_present
        end
      end
    end

    context "description" do
      it "説明文は500文字以内なら有効" do
        machi_repo.description = "あ" * 500
        expect(machi_repo).to be_valid
      end

      it "説明文は501文字以上なら無効" do
        machi_repo.description = "あ" * 501
        expect(machi_repo).to be_invalid
        expect(machi_repo.errors[:description]).to be_present
      end
    end

    context "hotspot_area_radius" do
      it "hotspot_area_radiusがnilなら有効" do
        machi_repo.hotspot_area_radius = nil
        expect(machi_repo).to be_valid
      end

      it "hotspot_area_radiusが正の整数なら有効" do
        machi_repo.hotspot_area_radius = 1
        expect(machi_repo).to be_valid
      end

      it "hotspot_area_radiusが0以下なら無効" do
        [0, -1].each do |value|
          machi_repo.hotspot_area_radius = value
          expect(machi_repo).to be_invalid
          expect(machi_repo.errors[:hotspot_area_radius]).to be_present
        end
      end

      it "hotspot_area_radiusが小数なら無効" do
        machi_repo.hotspot_area_radius = 3.14
        expect(machi_repo).to be_invalid
        expect(machi_repo.errors[:hotspot_area_radius]).to be_present
      end

      it "hotspot_area_radiusが文字列なら無効" do
        machi_repo.hotspot_area_radius = "ten"
        expect(machi_repo).to be_invalid
        expect(machi_repo.errors[:hotspot_area_radius]).to be_present
      end
    end
  end

  describe "enumの定義" do
    it "info_levelが定義されている" do
      expect(MachiRepo.info_levels.keys).to include("share", "warn", "emergency")
    end

    it "categoryが定義されている" do
      expect(MachiRepo.categories.keys).to include("crime", "disaster", "traffic", "children", "animal", "environment", "other")
    end

    it "hotspot_settingsが定義されている" do
      expect(MachiRepo.hotspot_settings.keys).to include("area", "pinpoint")
    end
  end

  describe "tag_namesのバリデーション" do
    it "タグが3個以内なら有効" do
      machi_repo.tag_names = "a,b,c"
      expect(machi_repo).to be_valid
    end

    it "タグが4個以上なら無効" do
      machi_repo.tag_names = "a,b,c,d"
      expect(machi_repo).to be_invalid
      expect(machi_repo.errors[:tag_names]).to be_present
    end

    it "タグの文字数が15文字以内でないと無効" do
      machi_repo.tag_names = "a" * 16
      expect(machi_repo).to be_invalid
      expect(machi_repo.errors[:tag_names]).to be_present
    end

    it "重複したタグがあると無効" do
      machi_repo.tag_names = "タグ,タグ"
      expect(machi_repo).to be_invalid
      expect(machi_repo.errors[:tag_names]).to be_present
    end

    it "空白やカンマだけのタグは無視される" do
      machi_repo.tag_names = ", , ,"
      expect(machi_repo).to be_valid
    end
  end

  describe "assign_tagsコールバック" do
    it "保存時にタグを割り当てる" do
      machi_repo.tag_names = "猫,子ども"
      expect {
        machi_repo.save!
      }.to change { Tag.count }.by(2)
      expect(machi_repo.tags.pluck(:name)).to match_array(["猫", "子ども"])
    end

    it "空白タグを無視する" do
      machi_repo.tag_names = "猫, ,犬"
      expect {
        machi_repo.save!
      }.to change { Tag.count }.by(2)
      expect(machi_repo.tags.pluck(:name)).to match_array(["猫", "犬"])
    end
  end
end
