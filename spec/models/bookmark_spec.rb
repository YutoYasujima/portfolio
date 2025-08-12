require "rails_helper"

RSpec.describe Bookmark, type: :model do
  describe "アソシエーション" do
    it "belongs_to :user" do
      assoc = Bookmark.reflect_on_association(:user)
      expect(assoc.macro).to eq :belongs_to
    end

    it "belongs_to :machi_repo" do
      assoc = Bookmark.reflect_on_association(:machi_repo)
      expect(assoc.macro).to eq :belongs_to
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(build(:bookmark)).to be_valid
    end

    it "同じ user_id と machi_repo_id の組み合わせは無効" do
      user = create(:user)
      machi_repo = create(:machi_repo)
      create(:bookmark, user: user, machi_repo: machi_repo)

      duplicate = Bookmark.new(user: user, machi_repo: machi_repo)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "異なる組み合わせは有効" do
      user1 = create(:user)
      user2 = create(:user)
      machi_repo1 = create(:machi_repo)
      machi_repo2 = create(:machi_repo)

      expect(build(:bookmark, user: user1, machi_repo: machi_repo1)).to be_valid
      expect(build(:bookmark, user: user1, machi_repo: machi_repo2)).to be_valid
      expect(build(:bookmark, user: user2, machi_repo: machi_repo1)).to be_valid
    end
  end
end
