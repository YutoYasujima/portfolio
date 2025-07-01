class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :chatable, polymorphic: true

  mount_uploader :image, ChatImageUploader

  validates :message, length: { maximum: 500 }
  validate  :message_or_image_present
  validate  :image_size_validation
  validate  :image_extension_validation

  private

  # messageかimageのどちらかは必須
  def message_or_image_present
    if message.blank? && image.blank?
      errors.add(:base, "メッセージまたは画像のいずれかを入力してください")
    end
  end

  # 画像サイズ用バリデーション
  def image_size_validation
    return unless image.present? && image.file.present?

    if image.file.size > 2.megabytes
      errors.add(:image, "は2MB以下のファイルをアップロードしてください")
    end
  end

  # 画像の拡張子用バリデーション
  def image_extension_validation
    return unless image.present? && image.file.present?

    extension = image.file.extension&.downcase
    unless %w[jpg jpeg gif png].include?(extension)
      errors.add(:image, "はJPG, JPEG, PNG, GIF形式のみアップロードできます")
    end
  end
end
