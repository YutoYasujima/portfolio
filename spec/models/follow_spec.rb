require "rails_helper"

RSpec.describe Follow, type: :model do
  describe "アソシエーション" do
    it "belongs_to :follower" do
      assoc = Follow.reflect_on_association(:follower)
      expect(assoc.macro).to eq :belongs_to
    end

    it "belongs_to :followed" do
      assoc = Follow.reflect_on_association(:followed)
      expect(assoc.macro).to eq :belongs_to
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(create(:follow)).to be_valid
    end

    it "follower_id がない場合は無効" do
      follow = build(:follow, follower: nil)
      expect(follow).to be_invalid
      expect(follow.errors[:follower_id]).to be_present
    end

    it "followed_id がない場合は無効" do
      follow = build(:follow, followed: nil)
      expect(follow).to be_invalid
      expect(follow.errors[:followed_id]).to be_present
    end

    it "同じ follower_id と followed_id の組み合わせは無効" do
      follower = create(:user)
      followed = create(:user)
      create(:follow, follower: follower, followed: followed)

      duplicate = build(:follow, follower: follower, followed: followed)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:follower_id]).to be_present
    end

    it "異なる組み合わせは有効" do
      follower1 = create(:user)
      follower2 = create(:user)
      followed1 = create(:user)
      followed2 = create(:user)

      expect(build(:follow, follower: follower1, followed: followed1)).to be_valid
      expect(build(:follow, follower: follower1, followed: followed2)).to be_valid
      expect(build(:follow, follower: follower2, followed: followed1)).to be_valid
    end
  end
end
