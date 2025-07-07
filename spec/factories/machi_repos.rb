FactoryBot.define do
  factory :machi_repo do
    association :user

    sequence(:title) { |n| "まちレポタイトル#{n}" }
    description { "地域に関する情報です。" }
    info_level { :share }
    category { :disaster }
    hotspot_settings { :area }
    hotspot_area_radius { 100 }
    # 東京駅：東京都千代田区 latitude: 35.6812996, longitude: 139.7670658
    latitude { 35.6812996 }
    longitude { 139.7670658 }
    address { "東京都千代田区" }

    # traits で追加要素をオプションに
    trait :with_image do
      image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.jpeg"), "image/jpeg") }
    end

    trait :with_tags do
      after(:create) do |repo|
        repo.tags << create_list(:tag, 2)
      end
    end

    trait :with_chats do
      after(:create) do |repo|
        create_list(:chat, 3, chatable: repo)
      end
    end
  end
end
