module ApplicationHelper
  CATEGORY_EMOJIS = {
    "crime" => "🚨",
    "disaster" => "🌀",
    "traffic" => "🚦",
    "children" => "🧒",
    "animal" => "🐶",
    "environment" => "🏠",
    "other" => "🎈"
  }.freeze

  # マップ上に表示するカテゴリー用絵文字を取得する
  def display_machi_repo_category_emoji(category)
    CATEGORY_EMOJIS[category] || "🎈"
  end

  # アスペクト比を維持した画像の高さを取得する
  def aspect_height_style_for_chat_image(chat, width_em: 13, em_px: 16)
    return "" unless chat.image? && chat.image_width.present? && chat.image_height.present?

    width_px = width_em * em_px
    aspect_ratio = chat.image_height.to_f / chat.image_width
    height_px = (width_px * aspect_ratio).round

    "height: #{height_px}px;"
  end
end
