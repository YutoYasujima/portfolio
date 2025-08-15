FactoryBot.define do
  factory :profile do
    association :user
    association :prefecture
    association :municipality
    sequence(:nickname) { |n| "user_nickname_#{n}" }
    bio { "This is a sample bio." }

    # traits で追加要素をオプションに
    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.jpeg"), "image/jpeg") }
    end
  end
end
