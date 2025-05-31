class CreateChats < ActiveRecord::Migration[8.0]
  def change
    create_table :chats do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.string :image
      t.references :chatable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
