class CreateCommunities < ActiveRecord::Migration[8.0]
  def change
    create_table :communities do |t|
      t.references :prefecture, null: false, foreign_key: true
      t.references :municipality, null: false, foreign_key: true
      t.string :name, null: false
      t.string :icon
      t.text :description

      t.timestamps
    end

    # 同じ自治体内で重複するコミュニティ名はダメ
    add_index :communities, [ :prefecture_id, :municipality_id, :name ], unique: true
  end
end
