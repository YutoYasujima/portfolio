FactoryBot.define do
  factory :chat do
    association :user
    association :chatable, factory: :machi_repo
    message { "チャットのメッセージ" }
    image { nil }
  end
end
