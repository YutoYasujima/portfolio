require "rails_helper"

RSpec.describe CommunityChatRead, type: :model do
  describe "アソシエーション" do
    it "belongs_to :user" do
      assoc = CommunityChatRead.reflect_on_association(:user)
      expect(assoc.macro).to eq :belongs_to
    end

    it "belongs_to :community" do
      assoc = CommunityChatRead.reflect_on_association(:community)
      expect(assoc.macro).to eq :belongs_to
    end
  end

  describe "バリデーション" do
    it "正常な場合は有効" do
      expect(build(:community_chat_read)).to be_valid
    end

    it "last_read_chat_id が整数でない場合は無効" do
      record = build(:community_chat_read, last_read_chat_id: 0.1)
      expect(record).to be_invalid
      expect(record.errors[:last_read_chat_id]).to be_present
    end

    it "同じ user_id と community_id の組み合わせは無効" do
      user = create(:user)
      community = create(:community)
      create(:community_chat_read, user: user, community: community)

      duplicate = build(:community_chat_read, user: user, community: community)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "異なる user_id または community_id の組み合わせは有効" do
      user1 = create(:user)
      user2 = create(:user)
      community1 = create(:community)
      community2 = create(:community)

      expect(build(:community_chat_read, user: user1, community: community1)).to be_valid
      expect(build(:community_chat_read, user: user1, community: community2)).to be_valid
      expect(build(:community_chat_read, user: user2, community: community1)).to be_valid
    end
  end
end
