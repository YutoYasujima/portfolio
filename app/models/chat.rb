class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :chatable, polymorphic: true

  before_save :set_image_dimensions, if: -> { image.present? && image_changed? }

  mount_uploader :image, ChatImageUploader

  validates :message, length: { maximum: 500 }

  private

  # 画像の横幅と高さを設定する
  def set_image_dimensions
    return unless image&.file&.exists?

    img = MiniMagick::Image.open(image.file.file)
    self.image_width = img.width
    self.image_height = img.height
  end
end
