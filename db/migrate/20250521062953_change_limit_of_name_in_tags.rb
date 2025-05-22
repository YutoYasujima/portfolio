class ChangeLimitOfNameInTags < ActiveRecord::Migration[8.0]
  def change
    change_column :tags, :name, :string, limit: 15
  end
end
