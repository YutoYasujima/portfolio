class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile
  has_many :machi_repos, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmark_machi_repos, through: :bookmarks, source: :machi_repo

  attr_accessor :agreement
  validates :agreement, acceptance: { accept: "1", message: "に同意してください" }

  # Googleログイン(OmniAuth)を通じて認証されたユーザー情報から、
  # アプリ側のUserレコードを探す or 作成する処理
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      # ログインには使用しないが、Deviseでpasswordが必要な場合に備えて
      user.password = Devise.friendly_token[0, 20]
      # Googleログイン時はメール確認をスキップ
      user.skip_confirmation_notification!
      # confirmモジュールはconfirmedの値がnilだとメール確認が必要だと判断するため代入
      user.confirmed_at = Time.current
    end
  end

  # マイタウンの「"都道府県""市区町村"」を取得
  def mytown_address
    profile.prefecture.name_kanji + profile.municipality.name_kanji
  end

  def bookmark(machi_repo)
    bookmark_machi_repos << machi_repo
  end

  def unbookmark(machi_repo)
    bookmark_machi_repos.destroy(machi_repo)
  end

  def bookmark?(machi_repo)
    bookmark_machi_repos.include?(machi_repo)
  end
end
