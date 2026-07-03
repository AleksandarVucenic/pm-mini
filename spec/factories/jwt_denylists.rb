FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2026-07-03 15:26:07" }
  end
end
