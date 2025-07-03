FactoryBot.define do
  factory :profile do
    association :user
    association :prefecture
    association :municipality
    sequence(:nickname) { |n| "user_nickname_#{n}" }
    bio { "This is a sample bio." }
  end
end
