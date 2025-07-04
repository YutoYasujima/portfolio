require "rails_helper"

RSpec.describe MachiRepoTag, type: :model do
  describe "アソシエーション" do
    it "belongs_to :machi_repo" do
      assoc = MachiRepoTag.reflect_on_association(:machi_repo)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "belongs_to :tag" do
      assoc = MachiRepoTag.reflect_on_association(:tag)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(build(:machi_repo_tag)).to be_valid
    end

    it "同じ machi_repo_id と tag_id の組み合わせは無効" do
      machi_repo = create(:machi_repo)
      tag = create(:tag)
      create(:machi_repo_tag, machi_repo: machi_repo, tag: tag)

      duplicate = MachiRepoTag.new(machi_repo: machi_repo, tag: tag)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:machi_repo_id]).to be_present
    end

    it "異なる組み合わせは有効" do
      machi_repo1 = create(:machi_repo)
      machi_repo2 = create(:machi_repo)
      tag1 = create(:tag)
      tag2 = create(:tag)

      expect(build(:machi_repo_tag, machi_repo: machi_repo1, tag: tag1)).to be_valid
      expect(build(:machi_repo_tag, machi_repo: machi_repo1, tag: tag2)).to be_valid
      expect(build(:machi_repo_tag, machi_repo: machi_repo2, tag: tag1)).to be_valid
    end
  end
end
