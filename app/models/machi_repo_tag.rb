class MachiRepoTag < ApplicationRecord
  belongs_to :machi_repo
  belongs_to :tag

  validates :machi_repo_id, uniqueness: { scope: :tag_id }
end
