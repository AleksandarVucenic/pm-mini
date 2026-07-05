require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let!(:kirk) { User.create!(name: "Kirk", email: "kirk_u@test.com", password: "12345678") }
  let!(:spock) { User.create!(name: "Spock", email: "spock_u@test.com", password: "12345678") }

  def auth_headers(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "12345678" } }
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/users" do
    it "returns all users to any authenticated user" do
      get "/api/v1/users", headers: auth_headers(kirk)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to be >= 2
    end

    it "returns unauthorized without a token" do
      get "/api/v1/users"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns user attributes (name and email)" do
      get "/api/v1/users", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      attrs = json["data"].first["attributes"]
      expect(attrs).to have_key("name")
      expect(attrs).to have_key("email")
    end

    it "includes pagination meta" do
      get "/api/v1/users?per_page=1", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["meta"]["current_page"]).to eq(1)
      expect(json["meta"]["page_size"]).to eq(1)
      expect(json["meta"]["total_count"]).to be >= 2
    end

    it "returns the second page correctly" do
      get "/api/v1/users?per_page=1&page=2", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["meta"]["current_page"]).to eq(2)
    end
  end
end
