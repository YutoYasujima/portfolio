FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    confirmed_at { Time.current }
    agreement { "1" }

    trait :with_profile do
      after(:create) do |user|
        create(:profile, user: user)
      end
    end
  end
end