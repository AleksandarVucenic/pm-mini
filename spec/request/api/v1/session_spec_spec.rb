require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let!(:user) { User.create!(name: "Kirk", email: "kirk@test.com", password: "12345678") }

  describe "POST /api/v1/login" do
    it "returns a token in the Authorization header with valid credentials" do
      post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "12345678" } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present

      json = JSON.parse(response.body)
      expect(json["success"]).to eq(true)
      expect(json["data"]["user"]["email"]).to eq("kirk@test.com")
    end

    it "returns unauthorized with wrong password" do
      post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "wrongpassword" } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized with non-existent email" do
      post "/api/v1/login", params: { user: { email: "noexists@test.com", password: "12345678" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "revokes the token so it can no longer be used" do
      post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "12345678" } }
      token = response.headers["Authorization"]

      delete "/api/v1/logout", headers: { "Authorization" => token }
      expect(response).to have_http_status(:ok)

      get "/api/v1/users", headers: { "Authorization" => token }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized when no token is provided" do
      delete "/api/v1/logout"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end