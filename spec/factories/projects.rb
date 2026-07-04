FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    association :pm, factory: :user
  end
end
