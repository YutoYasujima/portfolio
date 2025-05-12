class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :prefecture
  belongs_to :municipality

  validates :nickname, presence: true, length: { maximum: 20 }
  validates :identifier, presence: true, uniqueness: true, length: { maximum: 10 }, format: { with: /\A[a-zA-Z0-9_\-]+\z/, message: "は英数字、アンダースコア、ハイフンのみ使用できます" }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :avatar, length: { maximum: 255 }, allow_blank: true, format: { with: /\Ahttps?:\/\/.+\.(jpg|jpeg|png|gif)\z/, message: "は「.jpg, .jpeg, .png, .gif」形式でなければなりません" }
end
