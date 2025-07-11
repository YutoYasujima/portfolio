class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :machi_repo, null: false, foreign_key: true

      t.timestamps
    end

    add_index :bookmarks, [ :user_id, :machi_repo_id ], unique: true
  end
end
