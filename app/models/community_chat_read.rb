class CommunityChatRead < ApplicationRecord
  belongs_to :user
  belongs_to :community

  validates :last_read_chat_id, numericality: { only_integer: true }
  validates :user_id, uniqueness: { scope: :community_id }  # 同じユーザーが同じコミュニティで複数行を持たないように
end
