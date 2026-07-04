FactoryBot.define do
  factory :task do
    title { "Fix warp core" }
    description { "A routine repair task" }
    status { :open }
    project

    trait :closed do
      status { :closed }
    end

    trait :with_assignee do
      association :assignee, factory: :user
    end
  end
end
