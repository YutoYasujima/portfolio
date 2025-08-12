require "rails_helper"

RSpec.describe CommunityMembership, type: :model do
  describe "アソシエーション" do
    it "belongs_to :user" do
      assoc = CommunityMembership.reflect_on_association(:user)
      expect(assoc.macro).to eq :belongs_to
    end

    it "belongs_to :community" do
      assoc = CommunityMembership.reflect_on_association(:community)
      expect(assoc.macro).to eq :belongs_to
    end
  end

  describe "バリデーション" do
    it "正常な入力の場合" do
      expect(build(:community_membership)).to be_valid
    end

    it "同じ user_id と community_id の組み合わせは無効" do
      user = create(:user)
      community = create(:community)
      create(:community_membership, user: user, community: community)

      duplicate = build(:community_membership, user: user, community: community)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "異なる user と community の組み合わせは有効" do
      user1 = create(:user)
      user2 = create(:user)
      community1 = create(:community)
      community2 = create(:community)

      expect(build(:community_membership, user: user1, community: community1)).to be_valid
      expect(build(:community_membership, user: user1, community: community2)).to be_valid
      expect(build(:community_membership, user: user2, community: community1)).to be_valid
    end
  end

  describe "enum" do
    it "roleのデフォルトは general" do
      membership = build(:community_membership)
      expect(membership.role).to eq "general"
    end

    it "statusのデフォルトは requested" do
      membership = build(:community_membership)
      expect(membership.status).to eq "requested"
    end

    it "roleが設定できること" do
      %i[general sub leader].each do |role|
        expect(build(:community_membership, role: role)).to be_valid
      end
    end

    it "statusが設定できること" do
      %i[requested invited approved rejected cancelled withdrawn kicked].each do |status|
        expect(build(:community_membership, status: status)).to be_valid
      end
    end
  end
end
