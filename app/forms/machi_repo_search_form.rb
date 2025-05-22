class MachiRepoSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # モデルに関連する検索条件
  attribute :title, :string
  attribute :info_level, :string
  attribute :category, :string
  attribute :address, :string
  attribute :latitude, :float
  attribute :longitude, :float
  attribute :tag_names, :string

  # モデルに関係ない条件
  attribute :tag_match_type, :string, default: "or"
  attribute :display_range_radius, :integer, default: 1000
  attribute :display_hotspot_count, :integer, default: 20
  attribute :start_date, :datetime
  attribute :end_date, :datetime

  validate :start_date_should_be_before_end_date

  # 周辺のホットスポット検索
  def search_near_hotspots
    # ホットスポット表示範囲
    scope = MachiRepo.near([ latitude, longitude ], (display_range_radius.to_f / 1000))
    # 検索条件付与
    scope = filter_machi_repos(scope)
    # マップ上のホットスポット表示数分のデータ取得
    scope.limit(display_hotspot_count)
  end

  # "まち"のまちレポ検索
  def search_machi_repos
    scope = MachiRepo.where(address: address)
    # 検索条件付与
    scope = filter_machi_repos(scope)
    # N+1問題対応
    scope.includes(:tags, user: :profile).order(created_at: :desc)
  end

  private

  # MachiRepoデータのフィルタリング
  def filter_machi_repos(scope)
    # タイトル(曖昧 複数)
    if title.present?
      # 全角・半角スペースで分割し、空文字を除外
      title_keywords = title.strip.split(/[\s　]+/).reject(&:empty?)

      if title_keywords.present?
        title_keywords.each do |keyword|
          escaped_keyword = ActiveRecord::Base.sanitize_sql_like(keyword)
          scope = scope.where("title LIKE ?", "%#{escaped_keyword}%")
        end
      end
    end

    # 情報レベル
    scope = scope.where(info_level: info_level) if info_level.present?

    # カテゴリー
    scope = scope.where(category: category) if category.present?

    # タグ
    if tag_names.present?
      tag_list = tag_names.split(",").map(&:strip).reject(&:empty?).uniq.first(3)
      if tag_list.present?
        if tag_match_type == "and"
          # and検索
          scope = scope.joins(:tags)
            .where(tags: { name: tag_list })
            .group("machi_repos.id")
            .having("COUNT(DISTINCT tags.id) = ?", tag_list.size)
        else
          # or検索
          scope = scope.joins(:tags).where(tags: { name: tag_list }).distinct
        end
      end
    end

    # まちレポ作成日
    if start_date.present? && end_date.present?
      # 検索開始日と終了日の前後関係が正しい
      if start_date <= end_date
        scope = scope.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      end
    elsif start_date.present?
      scope = scope.where("created_at >= ?", start_date.beginning_of_day)
    elsif end_date.present?
      scope = scope.where("created_at <= ?", end_date.end_of_day)
    end

    scope
  end

  # 日付の前後関係チェック
  def start_date_should_be_before_end_date
    return if start_date.blank? || end_date.blank?
    if start_date > end_date
      errors.add(:base, "まちレポ作成日を確認してください")
    end
  end
end
