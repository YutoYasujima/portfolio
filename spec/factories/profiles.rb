FactoryBot.define do
  factory :profile do
    association :user
    association :prefecture
    association :municipality
    sequence(:nickname) { |n| "user_nickname_#{n}" }
    sequence(:identifier) { |n| "user_id_#{n}" }
    bio { "This is a sample bio." }
  end
end
