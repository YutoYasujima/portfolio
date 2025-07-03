FactoryBot.define do
  factory :machi_repo do
    association :user
    title { "タイトル" }
    info_level { 0 }
    category { 0 }
    description { "説明文" }
    hotspot_settings { 0 }
    hotspot_area_radius { 100 }
    latitude { 35.6895 }
    longitude { 139.6917 }
    address { "東京都千代田区" }
  end
end
