class MachiRepo < ApplicationRecord
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
end
