require "rails_helper"

RSpec.describe "Api::V1::Projects", type: :request do
  let(:kirk) { User.create!(name: "Kirk", email: "kirk_p@test.com", password: "sigurna123") }
  let(:spock) { User.create!(name: "Spock", email: "spock_p@test.com", password: "sigurna123") }

  def auth_headers(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "sigurna123" } }
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/projects" do
    it "returns all projects to any authenticated user" do
      Project.create!(name: "Project A", pm: kirk)
      Project.create!(name: "Project B", pm: spock)

      get "/api/v1/projects", headers: auth_headers(kirk)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(2)
    end

    it "returns unauthorized without a token" do
      get "/api/v1/projects"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/projects" do
    it "creates a project with the current user set as pm" do
      post "/api/v1/projects", params: { project: { name: "Enterprise Refit" } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["name"]).to eq("Enterprise Refit")
      expect(json["data"]["pm"]["id"]).to eq(kirk.id)
    end

    it "ignores a pm_id sent in the request body" do
      post "/api/v1/projects",
           params: { project: { name: "Enterprise Refit", pm_id: spock.id } },
           headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"]["pm"]["id"]).to eq(kirk.id)
    end

    it "returns validation errors without a name" do
      post "/api/v1/projects", params: { project: { name: "" } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "shows a single project to any authenticated user" do
      project = Project.create!(name: "Project A", pm: kirk)

      get "/api/v1/projects/#{project.id}", headers: auth_headers(spock)

      expect(response).to have_http_status(:ok)
    end

    it "returns not_found for a nonexistent project" do
      get "/api/v1/projects/999999", headers: auth_headers(kirk)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    it "updates the project name" do
      project = Project.create!(name: "Old Name", pm: kirk)

      patch "/api/v1/projects/#{project.id}", params: { project: { name: "New Name" } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:ok)
      expect(project.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes the project" do
      project = Project.create!(name: "To Delete", pm: kirk)

      delete "/api/v1/projects/#{project.id}", headers: auth_headers(kirk)

      expect(response).to have_http_status(:ok)
      expect(Project.exists?(project.id)).to be false
    end
  end
end