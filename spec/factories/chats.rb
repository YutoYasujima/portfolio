FactoryBot.define do
  factory :chat do
    association :user
    message { "チャットのメッセージ" }
    image { nil }

    # デフォルトは machi_repo に紐付け
    association :chatable, factory: :machi_repo

    trait :for_community do
      association :chatable, factory: :community
    end

    # traits で追加要素をオプションに
    trait :with_image do
      image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/sample.jpeg"), "image/jpeg") }
    end
  end
end
