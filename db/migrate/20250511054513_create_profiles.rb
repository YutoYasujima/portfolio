class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :prefecture, null: false, foreign_key: true
      t.references :municipality, null: false, foreign_key: true
      t.string :nickname, null: false
      t.string :identifier, null: false
      t.text :bio
      t.string :avatar

      t.timestamps
    end

    add_index :profiles, :identifier, unique: true
  end
end
