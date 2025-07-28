class CommunitySearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # モデルに関連する検索条件
  attribute :name, :string
  attribute :prefecture_id, :integer
  attribute :municipality_id, :integer

  def search_communities(user)
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

    # 重複削除
    scope = scope.distinct

    # 各コミュニティのメンバー数取得
    ## 上記で取得するコミュニティのIDを取得
    community_ids = scope.select(:id)

    ## 各コミュニティのメンバー数を取得
    approved_memberships = CommunityMembership
    .select("community_id, COUNT(*) AS approved_count")
    .where(status: :approved, community_id: community_ids)
    .group(:community_id)

    ## メンバー数の集計結果を結合
    scope = scope
      .joins("LEFT OUTER JOIN (#{approved_memberships.to_sql}) AS memberships_count ON memberships_count.community_id = communities.id")
      .select("communities.*, COALESCE(memberships_count.approved_count, 0) AS approved_members_count")

    # ユーザーのstatusで並び替え
    ## userとのmembershipを外部結合
    scope = scope
    .joins(<<~SQL)
      LEFT OUTER JOIN community_memberships AS current_user_membership
        ON current_user_membership.community_id = communities.id
        AND current_user_membership.user_id = #{user.id}
    SQL

    ## 結合したstatusをソート用の値に変換する
    scope = scope.select(<<~SQL)
      current_user_membership.status AS user_membership_status,
      CASE current_user_membership.status
        WHEN #{CommunityMembership.statuses[:approved]} THEN 1
        WHEN #{CommunityMembership.statuses[:invited]} THEN 2
        WHEN #{CommunityMembership.statuses[:requested]} THEN 3
        ELSE 4
      END AS user_membership_priority
    SQL

    ## ステータス順 + 更新日時
    scope = scope.order("user_membership_priority ASC, communities.updated_at DESC")

    scope
  end
end
