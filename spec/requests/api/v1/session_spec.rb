require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let!(:user) { User.create!(name: "Kirk", email: "kirk@test.com", password: "password123") }

  describe "POST /api/v1/login" do
    it "returns a token in the Authorization header with valid credentials" do
      post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "password123" } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present

      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["email"]).to eq("kirk@test.com")
    end

    it "returns unauthorized with wrong password in JSON:API error format" do
      post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "wrongpassword" } }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["errors"].first["status"]).to eq("401")
    end

    it "returns the same error for wrong password and non-existent email (no user enumeration)" do
      post "/api/v1/login", params: { user: { email: "ghost@test.com", password: "password123" } }
      ghost_body = response.body

      post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "wrongpassword" } }
      wrong_pw_body = response.body

      expect(JSON.parse(ghost_body)["errors"].first["detail"]).to eq(JSON.parse(wrong_pw_body)["errors"].first["detail"])
    end
  end

  describe "DELETE /api/v1/logout" do
    it "revokes the token so it can no longer be used" do
      post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "password123" } }
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

  describe "rate limiting" do
    it "blocks login after 5 failed attempts within 3 minutes" do
      6.times do
        post "/api/v1/login", params: { user: { email: "kirk@test.com", password: "wrong" } }
      end

      expect(response).to have_http_status(:too_many_requests)
      json = JSON.parse(response.body)
      expect(json["errors"].first["detail"]).to include("Too many login attempts")
    end
  end
end
