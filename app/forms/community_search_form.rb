class CommunitySearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # モデルに関連する検索条件
  attribute :name, :string
  attribute :prefecture_id, :integer
  attribute :municipality_id, :integer

  def search_communities
    scope = Community.all

    # コミュニティ名検索
    if name.present?
      # 全角・半角スペースで分割し、空文字を除外
      name_keywords = name.strip.split(/[\s　]+/).reject(&:empty?)

      name_keywords.each do |keyword|
        escaped_keyword = ActiveRecord::Base.sanitize_sql_like(keyword)
        scope = scope.where("name LIKE ?", "%#{escaped_keyword}%")
      end
    end

    # 都道府県
    scope = scope.where(prefecture_id: prefecture_id) if prefecture_id.present?

    # 市区町村
    scope = scope.where(municipality_id: municipality_id) if municipality_id.present?

    # 検索
    scope.distinct.includes(:community_memberships)
  end
end
