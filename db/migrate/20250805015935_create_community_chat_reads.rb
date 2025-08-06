class CreateCommunityChatReads < ActiveRecord::Migration[8.0]
  def change
    create_table :community_chat_reads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.integer :last_read_chat_id, null: false

      t.timestamps
    end

    add_index :community_chat_reads, [ :user_id, :community_id ], unique: true
  end
end
