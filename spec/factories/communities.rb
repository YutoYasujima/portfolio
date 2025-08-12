FactoryBot.define do
  factory :community do
    association :prefecture
    association :municipality
    sequence(:name) { |n| "コミュニティ#{n}" }
    description { "これは説明です。" }

    # traits で追加要素をオプションに
    trait :with_icon do
      icon { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.jpeg"), "image/jpeg") }
    end
  end
end
