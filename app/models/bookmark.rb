class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :machi_repo

  validates :user_id, uniqueness: { scope: :machi_repo_id }
end
