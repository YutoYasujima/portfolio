class CreatePrefectures < ActiveRecord::Migration[8.0]
  def change
    create_table :prefectures do |t|
      t.string :name_kanji, null: false, limit: 50
      t.string :name_kana, null: false, limit: 50

      t.timestamps
    end

    add_index :prefectures, :name_kanji, unique: true
    add_index :prefectures, :name_kana, unique: true
  end
end
