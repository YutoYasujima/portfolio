FactoryBot.define do
  factory :bookmark do
    association :user
    association :machi_repo
  end
end
