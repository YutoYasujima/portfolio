class MachiRepo < ApplicationRecord
  after_save :assign_tags
  after_initialize do
    self.tag_names ||= tags.map(&:name).join(",") if persisted?
  end

  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude

  attr_accessor :tag_names

  mount_uploader :image, MachiRepoImageUploader

  belongs_to :user
  has_many :machi_repo_tags, dependent: :destroy
  has_many :tags, through: :machi_repo_tags
  has_many :chats, as: :chatable, dependent: :destroy

  enum :info_level, {
    share: 0,         # 共有
    warn: 1,          # 警告
    emergency: 2      # 緊急
  }
  enum :category, {
    crime: 0,         # 防犯・治安
    disaster: 1,      # 災害・気象
    traffic: 2,       # 交通・道路環境
    children: 3,      # 子どもの安全
    animal: 4,        # ペット・動物
    environment: 5,   # 生活環境
    other: 100        # その他・気になること
  }
  enum :hotspot_settings, {
    area: 0,       # エリア指定
    pinpoint: 1    # ピンポイント指定
  }

  validates :title, presence: true, length: { maximum: 30 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :hotspot_area_radius, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate  :tag_names_validation

  private

  def tag_names_validation
    return unless tag_names.present?

    tags_array = tag_names.split(",").map(&:strip).reject(&:empty?)

    # タグ数上限チェック
    if tags_array.size > 3
      errors.add(:tag_names, "は3個まで入力できます")
    end

    # 各タグの文字数制限
    tags_array.each do |tag|
      if tag.length > 15
        errors.add(:tag_names, "の各タグは15文字以内で入力してください")
      end
    end

    # 重複チェック
    if tags_array.uniq.size != tags_array.size
      errors.add(:tag_names, "に重複したタグがあります")
    end
  end

  def assign_tags
    return if tag_names.nil?

    self.tags = tag_names.split(",").map(&:strip).reject(&:empty?).uniq.map do |tag_name|
      Tag.find_or_create_by(name: tag_name)
    end
  end
end
