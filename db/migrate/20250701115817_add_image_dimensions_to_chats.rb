class AddImageDimensionsToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :image_width, :integer
    add_column :chats, :image_height, :integer
  end
end
