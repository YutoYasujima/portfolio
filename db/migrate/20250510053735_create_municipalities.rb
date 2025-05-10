class CreateMunicipalities < ActiveRecord::Migration[8.0]
  def change
    create_table :municipalities do |t|
      t.references :prefecture, null: false, foreign_key: true
      t.string :name_kanji, null: false, limit: 50
      t.string :name_kana, null: false, limit: 50

      t.timestamps
    end

    add_index :municipalities, [ :prefecture_id, :name_kanji ], unique: true
  end
end
