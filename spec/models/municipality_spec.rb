require "rails_helper"

RSpec.describe Municipality, type: :model do
  subject(:municipality) { build(:municipality) }

  describe "アソシエーション" do
    it "belongs to prefecture" do
      assoc = Municipality.reflect_on_association(:prefecture)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(municipality).to be_valid
    end

    context "name_kanji" do
      it "name_kanji が存在しないと無効" do
        municipality.name_kanji = ""
        expect(municipality).to be_invalid
        expect(municipality.errors[:name_kanji]).to be_present
      end

      it "name_kanji が51文字以上だと無効" do
        municipality.name_kanji = "あ" * 51
        expect(municipality).to be_invalid
        expect(municipality.errors[:name_kanji]).to be_present
      end

      it "同じ都道府県内でname_kanjiが重複すると無効" do
        create(:municipality, prefecture: municipality.prefecture, name_kanji: "重複市")
        duplicate = build(:municipality, prefecture: municipality.prefecture, name_kanji: "重複市")
        expect(duplicate).to be_invalid
        expect(duplicate.errors[:name_kanji]).to be_present
      end

      it "異なる都道府県で同じname_kanjiなら有効" do
        create(:municipality, name_kanji: "同名市")
        other_prefecture = create(:prefecture)
        duplicate = build(:municipality, name_kanji: "同名市", prefecture: other_prefecture)
        expect(duplicate).to be_valid
      end
    end

    context "name_kana" do
      it "name_kana が存在しないと無効" do
        municipality.name_kana = ""
        expect(municipality).to be_invalid
        expect(municipality.errors[:name_kana]).to be_present
      end

      it "name_kana が51文字以上だと無効" do
        municipality.name_kana = "ア" * 51
        expect(municipality).to be_invalid
        expect(municipality.errors[:name_kana]).to be_present
      end
    end
  end
end
