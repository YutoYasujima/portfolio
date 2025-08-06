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

  # チャットの既読数表示
  def format_read_count(count)
    if count == 1
      "既読"
    elsif count >= 2
      "既読 #{count}"
    else
      ""
    end
  end

  # コミュニティに参加しているユーザー名取得(チャット用)
  def display_community_user_name(user, approved_user_ids)
    if approved_user_ids.include?(user.id)
      user.profile&.nickname || "(unknown)"
    else
      "(unknown)"
    end
  end
end
