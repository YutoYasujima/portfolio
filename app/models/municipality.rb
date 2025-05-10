class Municipality < ApplicationRecord
  belongs_to :prefecture

  validates :name_kanji, presence: true, length: { maximum: 50 }, uniqueness: { scope: :prefecture_id }
  validates :name_kana, presence: true, length: { maximum: 50 }
end
