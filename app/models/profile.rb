class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :prefecture
  belongs_to :municipality

  before_validation :set_unique_identifier, on: :create

  validates :nickname, presence: true, length: { maximum: 20 }
  validates :identifier, presence: true, uniqueness: true, length: { maximum: 10 }, format: { with: /\A[a-zA-Z0-9_\-]+\z/, message: "は英数字、アンダースコア、ハイフンのみ使用できます" }
  validates :bio, length: { maximum: 500 }, allow_blank: true

  attr_accessor :agreement
  validates :agreement, acceptance: { accept: "1", message: "に同意してください" }

  mount_uploader :avatar, ProfileAvatarUploader

  private

  # ランダム文字列の定義
  CHAR_SET = [ ("a".."z"), ("A".."Z"), ("0".."9"), [ "-", "_" ] ].map(&:to_a).flatten.freeze

  # Profileモデルのidentifierカラムの文字数
  IDENTIFIER_LENGTH = 10

  # Profileモデルのidentifierカラムのデフォルト値を生成
  def set_unique_identifier
    loop do
      # 10文字のランダムな文字列を生成
      self.identifier = Array.new(IDENTIFIER_LENGTH) { CHAR_SET.sample }.join
      # 生成された識別子がすでに存在しないかチェック
      break identifier unless Profile.exists?(identifier: identifier)
    end
  end
end
