class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :chatable, polymorphic: true

  mount_uploader :image, ChatImageUploader

  validates :message, length: { maximum: 500 }
end
