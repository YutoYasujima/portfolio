FactoryBot.define do
  factory :prefecture do
    sequence(:name_kanji) { |n| "都道府県#{n}" }
    sequence(:name_kana) { |n| "トドウフケン#{n}" }
  end
end
