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

  def display_machi_repo_category_emoji(category)
    CATEGORY_EMOJIS[category] || "🎈"
  end
end
