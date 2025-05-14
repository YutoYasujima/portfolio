class CreateMachiRepoTags < ActiveRecord::Migration[8.0]
  def change
    create_table :machi_repo_tags do |t|
      t.references :machi_repo, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :machi_repo_tags, [ :machi_repo_id, :tag_id ], unique: true
  end
end
