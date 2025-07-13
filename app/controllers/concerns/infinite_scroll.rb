module InfiniteScroll
  extend ActiveSupport::Concern

  included do
    helper_method :load_init_data, :load_more_data
  end

  # 無限スクロールの初期表示
  def load_init_data(table_name, total_records, per_page_num)
    @snapshot_time = Time.current
    session[:infinite_scroll_snapshot_time] = @snapshot_time.to_i

    model_class = table_name.classify.constantize
    arel_table = model_class.arel_table

    records_below_snapshot = total_records.where(arel_table[:updated_at].lteq(@snapshot_time))
    @total_records_count = records_below_snapshot.size

    @records = records_below_snapshot
                .order(arel_table[:updated_at].desc, arel_table[:id].desc)
                .limit(per_page_num)

    @is_last_page = @total_records_count <= per_page_num
  end

  # 無限スクロールの追加読み込み
  def load_more_data(table_name, total_records, per_page_num)
    snapshot_time = Time.at(session[:infinite_scroll_snapshot_time].to_i)
    cursor_updated_at = Time.at(params[:previous_last_updated].to_i)
    cursor_id = params[:previous_last_id].to_i

    model_class = table_name.classify.constantize
    arel_table = model_class.arel_table

    records_below_snapshot = total_records.where(arel_table[:updated_at].lteq(snapshot_time))
    @total_records_count = records_below_snapshot.size

    raw_records = records_below_snapshot
                  .where(
                    arel_table[:updated_at].lt(cursor_updated_at)
                    .or(arel_table[:updated_at].eq(cursor_updated_at)
                      .and(arel_table[:id].lt(cursor_id)))
                  )
                  .order(arel_table[:updated_at].desc, arel_table[:id].desc)
                  .limit(per_page_num + 1)

    @is_last_page = raw_records.size <= per_page_num
    @records = raw_records.first(per_page_num)
  end
end