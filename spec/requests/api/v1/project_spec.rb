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

  describe "POST /api/v1/projects" do
    it "creates a project with the current user set as pm" do
      post "/api/v1/projects", params: { project: { name: "Enterprise Refit" } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["name"]).to eq("Enterprise Refit")
      expect(json["data"]["relationships"]["pm"]["data"]["id"]).to eq(kirk.id.to_s)
    end

    it "ignores a pm_id sent in the request body" do
      post "/api/v1/projects",
           params: { project: { name: "Enterprise Refit", pm_id: spock.id } },
           headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"]["relationships"]["pm"]["data"]["id"]).to eq(kirk.id.to_s)
    end

    it "returns 400 when name is missing from the request" do
      post "/api/v1/projects", params: { project: {} }, headers: auth_headers(kirk)
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 when name is blank" do
      post "/api/v1/projects", params: { project: { name: "" } }, headers: auth_headers(kirk)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    it "updates the project name" do
      project = Project.create!(name: "Old Name", pm: kirk)

      patch "/api/v1/projects/#{project.id}", params: { project: { name: "New Name" } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:ok)
      expect(project.reload.name).to eq("New Name")
    end

    it "allows the pm to update their own project" do
      project = Project.create!(name: "Old Name", pm: kirk)

      patch "/api/v1/projects/#{project.id}", params: { project: { name: "New Name" } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:ok)
    end

    it "forbids a non-pm from updating the project" do
      project = Project.create!(name: "Old Name", pm: kirk)

      patch "/api/v1/projects/#{project.id}", params: { project: { name: "Hacked Name" } }, headers: auth_headers(spock)

      expect(response).to have_http_status(:forbidden)
      expect(project.reload.name).to eq("Old Name")
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes the project" do
      project = Project.create!(name: "To Delete", pm: kirk)

      delete "/api/v1/projects/#{project.id}", headers: auth_headers(kirk)

      expect(response).to have_http_status(:no_content)
      expect(Project.exists?(project.id)).to be false
    end

    it "forbids a non-pm from deleting the project" do
      project = Project.create!(name: "To Keep", pm: kirk)

      delete "/api/v1/projects/#{project.id}", headers: auth_headers(spock)

      expect(response).to have_http_status(:forbidden)
      expect(Project.exists?(project.id)).to be true
    end
  end

  describe "pagination" do
    it "includes pagination meta in the response" do
      3.times { |i| Project.create!(name: "Project #{i}", pm: kirk) }

      get "/api/v1/projects?per_page=2", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(2)
      expect(json["meta"]["current_page"]).to eq(1)
      expect(json["meta"]["page_size"]).to eq(2)
      expect(json["meta"]["total_count"]).to eq(3)
    end

    it "returns the second page correctly" do
      3.times { |i| Project.create!(name: "Project #{i}", pm: kirk) }

      get "/api/v1/projects?per_page=2&page=2", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["meta"]["current_page"]).to eq(2)
    end
  end
end
