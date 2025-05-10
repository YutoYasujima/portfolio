class Prefecture < ApplicationRecord
  has_many :municipalities, dependent: :destroy

  validates :name_kanji, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :name_kana, presence: true, uniqueness: true, length: { maximum: 50 }
end
