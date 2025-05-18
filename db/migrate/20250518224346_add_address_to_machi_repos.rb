class AddAddressToMachiRepos < ActiveRecord::Migration[8.0]
  def change
    add_column :machi_repos, :address, :string, null: false
    add_index :machi_repos, :address
  end
end
