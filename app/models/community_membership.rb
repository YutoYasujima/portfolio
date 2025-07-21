class CommunityMembership < ApplicationRecord
  belongs_to :user
  belongs_to :community

  enum :role, {
    general: 0,    # メンバー
    sub: 1,        # サブリーダー
    leader: 2      # リーダー
  }

  enum :status, {
    requested: 0, # 参加希望中
    invited: 1,   # スカウト中
    approved: 2,  # 参加中
    rejected: 3,  # 拒否済み
    cancelled: 4, # 参加前キャンセル
    withdrawn: 5, # 自主退会
    kicked: 6     # 強制退会
  }

  validates :user_id, uniqueness: { scope: :community_id }
end
