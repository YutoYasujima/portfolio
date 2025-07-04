require "rails_helper"

RSpec.describe Tag, type: :model do
  subject(:tag) { build(:tag) }

  describe "アソシエーション" do
    context "静的なアソシエーション定義" do
      it "has_many :machi_repo_tags (dependent: :destroy)" do
        assoc = Tag.reflect_on_association(:machi_repo_tags)
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.options[:dependent]).to eq(:destroy)
      end

      it "has_many :machi_repos, through: :machi_repo_tags" do
        assoc = Tag.reflect_on_association(:machi_repos)
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.options[:through]).to eq(:machi_repo_tags)
      end
    end

    context "動作によるアソシエーション確認" do
      it "関連する machi_repo_tags を削除する" do
        tag = create(:tag)
        machi_repo = create(:machi_repo)
        machi_repo_tag = create(:machi_repo_tag, tag: tag, machi_repo: machi_repo)

        expect { tag.destroy }.to change { MachiRepoTag.count }.by(-1)
        expect(MachiRepoTag.where(id: machi_repo_tag.id)).to be_empty
      end
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(tag).to be_valid
    end

    it "nameが存在しないと無効" do
      tag.name = ""
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to be_present
    end

    it "nameが15文字以下なら有効" do
      tag.name = "a" * 15
      expect(tag).to be_valid
    end

    it "nameが16文字以上なら無効" do
      tag.name = "a" * 16
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to be_present
    end

    it "nameが重複していると無効" do
      create(:tag, name: "重複タグ")
      tag.name = "重複タグ"
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to be_present
    end
  end
end
