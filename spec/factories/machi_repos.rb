FactoryBot.define do
  factory :machi_repo do
    association :user

    sequence(:title) { |n| "まちレポタイトル#{n}" }
    description { "地域に関する情報です。" }
    info_level { :share }
    category { :disaster }
    hotspot_settings { :area }
    hotspot_area_radius { 100 }

    latitude { 35.6895 }
    longitude { 139.6917 }
    sequence(:address) { |n| "東京都千代田区#{n}" }

    # CarrierWave用ダミー画像（必要な場合）
    image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.png"), "image/png") }

    # traits で追加要素をオプションに
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
