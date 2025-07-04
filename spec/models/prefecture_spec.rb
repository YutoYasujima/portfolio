require "rails_helper"

RSpec.describe Prefecture, type: :model do
  subject(:prefecture) { build(:prefecture) }

  describe "アソシエーション" do
    context "静的なアソシエーション定義" do
      it "has many municipalities(dependent: :destroy)" do
        assoc = Prefecture.reflect_on_association(:municipalities)
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.options[:dependent]).to eq :destroy
      end
    end

    context "動作によるアソシエーション確認" do
      it "prefectureが削除時にmunicipalitiesも削除される" do
        municipality = create(:municipality, prefecture: prefecture)
        expect { prefecture.destroy }.to change { Municipality.count }.by(-1)
        expect(Municipality.where(id: municipality.id)).to be_empty
      end
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(prefecture).to be_valid
    end

    context "name_kanji" do
      it "空なら無効" do
        prefecture.name_kanji = ""
        expect(prefecture).not_to be_valid
        expect(prefecture.errors[:name_kanji]).to be_present
      end

      it "重複していると無効" do
        create(:prefecture, name_kanji: "東京都")
        prefecture.name_kanji = "東京都"
        expect(prefecture).not_to be_valid
        expect(prefecture.errors[:name_kanji]).to be_present
      end

      it "51文字以上なら無効" do
        prefecture.name_kanji = "あ" * 51
        expect(prefecture).not_to be_valid
        expect(prefecture.errors[:name_kanji]).to be_present
      end
    end

    context "name_kana" do
      it "空なら無効" do
        prefecture.name_kana = ""
        expect(prefecture).not_to be_valid
        expect(prefecture.errors[:name_kana]).to be_present
      end

      it "重複していると無効" do
        create(:prefecture, name_kana: "トウキョウト")
        prefecture.name_kana = "トウキョウト"
        expect(prefecture).not_to be_valid
        expect(prefecture.errors[:name_kana]).to be_present
      end

      it "51文字以上なら無効" do
        prefecture.name_kana = "ア" * 51
        expect(prefecture).not_to be_valid
        expect(prefecture.errors[:name_kana]).to be_present
      end
    end
  end
end
