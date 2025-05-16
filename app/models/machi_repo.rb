class MachiRepo < ApplicationRecord
  after_save :assign_tags
  after_initialize do
    self.tag_names ||= tags.map(&:name).join(', ') if persisted?
  end

  belongs_to :user
  has_many :machi_repo_tags, dependent: :destroy
  has_many :tags, through: :machi_repo_tags

  enum :info_level, {
    share: 0,         # 共有
    warn: 1,          # 警告
    emergency: 2      # 緊急
  }
  enum :category, {
    crime: 0,         # 防犯・治安
    disaster: 1,      # 災害・気象
    traffic: 2,       # 交通・道路環境
    children: 3,      # 子ども
    animal: 4,        # ペット・動物
    environment: 5,   # 生活環境
    other: 100        # その他・気になること
  }
  enum :hotspot_settings, {
    area: 0,       # エリア指定
    pinpoint: 1    # ピンポイント指定
  }

  attr_accessor :tag_names

  private

  def assign_tags
    return if tag_names.nil?

    self.tags = tag_names.split(',').map(&:strip).reject(&:empty?).uniq.map do |tag_name|
      Tag.find_or_create_by(name: tag_name)
    end
  end

end
