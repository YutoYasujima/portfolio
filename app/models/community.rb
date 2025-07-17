class Community < ApplicationRecord
  belongs_to :prefecture
  belongs_to :municipality
  has_many :chats, dependent: :destroy

  validates :name, presence: true, length: { maximum: 20 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  def base
    prefecture.name_kanji + municipality.name_kanji
  end

  mount_uploader :icon, CommunityIconUploader
end
