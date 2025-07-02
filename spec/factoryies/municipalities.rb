FactoryBot.define do
  factory :municipality do
    association :prefecture
    sequence(:name_kanji) { |n| "市区町村#{n}" }
    sequence(:name_kana) { |n| "シクチョウソン#{n}" }
  end
end