class Tag < ApplicationRecord
  has_many :machi_repo_tags, dependent: :destroy
  has_many :machi_repos, through: :machi_repo_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 15 }
end
