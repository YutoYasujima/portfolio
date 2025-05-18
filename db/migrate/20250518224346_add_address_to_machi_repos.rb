class AddAddressToMachiRepos < ActiveRecord::Migration[8.0]
  def change
    add_column :machi_repos, :address, :string
    add_index :machi_repos, :address

    # 既存データに仮の値を入れる
    reversible do |dir|
      dir.up do
        execute "UPDATE machi_repos SET address = '不明' WHERE address IS NULL"
      end
    end

    # 後からnull 制約を追加(先にやってしまうと既存のデータでNOT NULL制約違反が発生する)
    change_column_null :machi_repos, :address, false
  end
end
