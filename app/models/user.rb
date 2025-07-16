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
  # 自分がフォローしている関係
  has_many :active_follows, class_name: "Follow",
                            foreign_key: "follower_id",
                            dependent: :destroy
  has_many :followings, through: :active_follows, source: :followed
  # 自分をフォローしている関係
  has_many :passive_follows, class_name: "Follow",
                              foreign_key: "followed_id",
                              dependent: :destroy
  has_many :followers, through: :passive_follows, source: :follower

  attr_accessor :agreement
  validates :agreement, acceptance: { accept: "1", message: "に同意してください" }
  validate :email_must_be_different, on: :email_update

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

  # Googleアカウントか確認する
  def google_account?
    provider == "google_oauth2"
  end

  # ブックマークに追加する
  def bookmark(machi_repo)
    bookmark_machi_repos << machi_repo
  end

  # ブックマークを解除する
  def unbookmark(machi_repo)
    bookmark_machi_repos.destroy(machi_repo)
  end

  # ブックマークリストに存在するか確認する
  def bookmark?(machi_repo)
    bookmark_machi_repos.include?(machi_repo)
  end

  # フォローする
  def follow(user)
    followings << user
  end

  # フォロー解除する
  def unfollow(user)
    followings.destroy(user)
  end

  # フォロー中のユーザーか確認する
  def follow?(user)
    followings.include?(user)
  end

  # パスワード変更期限をチェックする
  def change_password_period_valid?
    change_password_sent_at && change_password_sent_at >= 1.hours.ago
  end

  private

  # email変更チェック
  def email_must_be_different
    if email.present? && email == email_was
      errors.add(:email, "は現在のものと異なるものを入力してください")
    end
  end
end
