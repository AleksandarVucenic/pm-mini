require "rails_helper"

RSpec.describe "Factories" do
  it "has valid factories" do
    expect(build(:user)).to be_valid
    expect(build(:project)).to be_valid
    expect(build(:task)).to be_valid
  end
end
