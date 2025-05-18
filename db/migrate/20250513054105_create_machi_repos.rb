class CreateMachiRepos < ActiveRecord::Migration[8.0]
  def change
    create_table :machi_repos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, limit: 30
      t.integer :info_level, null: false, default: 0
      t.integer :category, null: false, default: 0
      t.text :description, limit: 500
      t.integer :hotspot_settings, null: false, default: 0
      t.integer :hotspot_area_radius
      t.string :address, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :image
      t.integer :views_count, null: false, default: 0

      t.timestamps
    end

    add_index :machi_repos, :address
  end
end
