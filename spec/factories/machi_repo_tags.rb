FactoryBot.define do
  factory :machi_repo_tag do
    association :machi_repo
    association :tag
  end
end
