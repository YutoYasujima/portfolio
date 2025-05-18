class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile
  has_many :machi_repos, dependent: :destroy

  attr_accessor :agreement

  validates :agreement, acceptance: { accept: "1", message: "に同意してください" }

  def mytown_address
    profile.prefecture.name_kanji + profile.municipality.name_kanji
  end
end
