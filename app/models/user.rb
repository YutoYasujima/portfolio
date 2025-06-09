class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile
  has_many :machi_repos, dependent: :destroy
  has_many :chats, dependent: :destroy

  attr_accessor :agreement

  validates :agreement, acceptance: { accept: "1", message: "に同意してください" }

  # マイタウンの「"都道府県""市区町村"」を取得
  def mytown_address
    profile.prefecture.name_kanji + profile.municipality.name_kanji
  end
end
