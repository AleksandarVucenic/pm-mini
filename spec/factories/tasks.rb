FactoryBot.define do
  factory :task do
    title { "Fix warp core" }
    description { "A routine repair task" }
    closed { false }
    project

    trait :closed do
      closed { true }
    end

    trait :with_assignee do
      association :assignee, factory: :user
    end
  end
end
