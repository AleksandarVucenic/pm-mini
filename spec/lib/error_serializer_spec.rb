require "rails_helper"

RSpec.describe ErrorSerializer do
  describe ".from_message" do
    it "builds a JSON:API error with numeric status as string" do
      result = described_class.from_message("Not authorized", status: :forbidden)

      expect(result[:errors].first[:status]).to eq("403")
      expect(result[:errors].first[:title]).to eq("Forbidden")
      expect(result[:errors].first[:detail]).to eq("Not authorized")
    end
  end

  describe ".from_active_record_errors" do
    it "builds one error object per validation message" do
      user = User.new
      user.valid?

      result = described_class.from_active_record_errors(user.errors)

      expect(result[:errors]).to be_an(Array)
      expect(result[:errors].all? { |e| e[:title] == "Validation Error" }).to be true
    end
  end
end
