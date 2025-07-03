FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current } # Devise confirmable用
    agreement { "1" } # 仮想属性でバリデーションに必要

    trait :with_profile do
      after(:build) do |user|
        user.profile ||= build(:profile, user: user)
      end
    end

    trait :google_authenticated do
      provider { "google_oauth2" }
      uid { SecureRandom.uuid }
    end
  end
end
