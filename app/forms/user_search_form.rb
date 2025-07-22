class UserSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # モデルに関連する検索条件
  attribute :nickname, :string
  attribute :identifier, :string
  attribute :prefecture_id, :integer
  attribute :municipality_id, :integer

  # コミュニティスカウトのための検索
  def search_user_for_scout(community)
    scope = User.joins(:profile)
                .left_outer_joins(:community_memberships)
                .where("community_memberships.community_id IS NULL OR (community_memberships.community_id = ? AND community_memberships.status != ?)",
                community.id,
                CommunityMembership.statuses[:approved])

    # ニックネーム検索
    if nickname.present?
      # 全角・半角スペースで分割し、空文字を除外
      nickname_keywords = nickname.strip.split(/[\s　]+/).reject(&:empty?)

      nickname_keywords.each do |keyword|
        escaped_keyword = ActiveRecord::Base.sanitize_sql_like(keyword)
        scope = scope.where("profiles.nickname LIKE ?", "%#{escaped_keyword}%")
      end
    end

    # ユーザーID
    scope = scope.where(profiles: { identifier: identifier }) if identifier.present?

    # 都道府県
    scope = scope.where(profiles: { prefecture_id: prefecture_id }) if prefecture_id.present?

    # 市区町村
    scope = scope.where(profiles: { municipality_id: municipality_id }) if municipality_id.present?

    # 検索
    scope.distinct.includes(:profile, :community_memberships)
  end
end
