FactoryBot.define do
  factory :community_chat_read do
    association :user
    association :community
    last_read_chat_id { 1 }
  end
end
