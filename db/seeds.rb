# 都道府県データを一括挿入（データがない場合のみ実行）
if Prefecture.count == 0
  prefectures = CSV.read(Rails.root.join('db/csv/prefectures.csv'), headers: true).map do |row|
    {
      id: row['id'],
      name_kanji: row['name_kanji'],
      name_kana: row['name_kana']
    }
  end

  Prefecture.insert_all(prefectures)
end

# 市区町村データを一括挿入（データがない場合のみ実行）
if Municipality.count == 0
  municipalities = CSV.read(Rails.root.join('db/csv/municipalities.csv'), headers: true).map do |row|
    {
      id: row['id'],
      prefecture_id: row['prefecture_id'],
      name_kanji: row['name_kanji'],
      name_kana: row['name_kana']
    }
  end

  Municipality.insert_all(municipalities)
end
