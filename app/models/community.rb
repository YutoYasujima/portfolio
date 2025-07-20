class Community < ApplicationRecord
  belongs_to :prefecture
  belongs_to :municipality
  has_many :chats, as: :chatable, dependent: :destroy
  has_many :community_memberships, dependent: :destroy
  has_many :users, through: :community_memberships
  has_many :requested_memberships, -> { where(status: :requested) }, class_name: "CommunityMembership"
  # statusがrequestedのユーザーを取得する
  has_many :requested_users, through: :requested_memberships, source: :user

  validates :name, presence: true, length: { maximum: 20 }, uniqueness: {
    scope: [ :prefecture_id, :municipality_id ],
    message: "は同じ都道府県・市区町村内で既に使われています"
  }
  validates :prefecture_id, presence: true
  validates :municipality_id, presence: true
  validates :description, length: { maximum: 500 }, allow_blank: true

  def base
    prefecture.name_kanji + municipality.name_kanji
  end

  def leader
    community_memberships.find_by(role: :leader)&.user
  end

  def sub_leaders
    users.joins(:community_memberships).where(community_memberships: { community_id: id, role: :sub })
  end

  def general_members
    community_memberships.approved.where(role: :general).includes(:user).map(&:user)
  end

  mount_uploader :icon, CommunityIconUploader
end
