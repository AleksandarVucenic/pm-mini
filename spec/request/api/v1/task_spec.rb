require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:kirk) { User.create!(name: "Kirk", email: "kirk_t@test.com", password: "123456789") }
  let(:spock) { User.create!(name: "Spock", email: "spock_t@test.com", password: "123456789") }
  let(:project) { Project.create!(name: "Enterprise Refit", pm: kirk) }

  def auth_headers(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "123456789" } }
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/tasks" do
    it "returns all tasks ordered by updated_at descending" do
      Task.create!(title: "Old", project: project, updated_at: 3.days.ago)
      Task.create!(title: "New", project: project, updated_at: 1.hour.ago)

      get "/api/v1/tasks", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      titles = json["data"].map { |t| t["attributes"]["title"] }
      expect(titles).to eq([ "New", "Old" ])
    end

    it "filters by status" do
      Task.create!(title: "Open task", project: project, status: :open)
      Task.create!(title: "Closed task", project: project, status: :closed)

      get "/api/v1/tasks?status=open", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["attributes"]["title"]).to eq("Open task")
    end

    it "filters by project_id" do
      other_project = Project.create!(name: "Voyager Refit", pm: kirk)
      Task.create!(title: "In Enterprise", project: project)
      Task.create!(title: "In Voyager", project: other_project)

      get "/api/v1/tasks?project_id=#{project.id}", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["attributes"]["title"]).to eq("In Enterprise")
    end
  end

  describe "POST /api/v1/tasks" do
    it "creates a task with valid params" do
      post "/api/v1/tasks", params: { task: { title: "Fix warp core", project_id: project.id } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["title"]).to eq("Fix warp core")
      expect(json["data"]["attributes"]["assignee"]).to be_nil
    end

    it "creates a task with an assignee" do
      post "/api/v1/tasks",
           params: { task: { title: "Fix warp core", project_id: project.id, assignee_id: spock.id } },
           headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["assignee"]["id"]).to eq(spock.id)
    end

    it "returns validation errors without a title" do
      post "/api/v1/tasks", params: { task: { project_id: project.id } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns validation errors when the assignee already has 5 open tasks in the project" do
      5.times { |i| Task.create!(title: "Task #{i}", project: project, assignee: spock, status: :open) }

      post "/api/v1/tasks",
           params: { task: { title: "One too many", project_id: project.id, assignee_id: spock.id, status: "open" } },
           headers: auth_headers(kirk)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    it "updates the task" do
      task = Task.create!(title: "Old title", project: project)

      patch "/api/v1/tasks/#{task.id}", params: { task: { title: "New title" } }, headers: auth_headers(kirk)

      expect(response).to have_http_status(:ok)
      expect(task.reload.title).to eq("New title")
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    it "deletes the task" do
      task = Task.create!(title: "To delete", project: project)

      delete "/api/v1/tasks/#{task.id}", headers: auth_headers(kirk)

      expect(response).to have_http_status(:no_content)
      expect(Task.exists?(task.id)).to be false
    end
  end

  describe "authorization" do
    let(:mccoy) { User.create!(name: "McCoy", email: "mccoy_t@test.com", password: "123456789") }

    it "pm can see all tasks in their project, including unassigned ones" do
      Task.create!(title: "Assigned to Spock", project: project, assignee: spock)
      Task.create!(title: "Unassigned", project: project)

      get "/api/v1/tasks", headers: auth_headers(kirk)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(2)
    end

    it "assignee only sees tasks assigned to them" do
      Task.create!(title: "Assigned to Spock", project: project, assignee: spock)
      Task.create!(title: "Assigned to McCoy", project: project, assignee: mccoy)

      get "/api/v1/tasks", headers: auth_headers(spock)

      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["attributes"]["title"]).to eq("Assigned to Spock")
    end

    it "forbids a non-pm from creating a task" do
      post "/api/v1/tasks", params: { task: { title: "Sneaky task", project_id: project.id } }, headers: auth_headers(spock)

      expect(response).to have_http_status(:forbidden)
    end

    it "allows the assignee to update their own task" do
      task = Task.create!(title: "My task", project: project, assignee: spock)

      patch "/api/v1/tasks/#{task.id}", params: { task: { status: "closed" } }, headers: auth_headers(spock)

      expect(response).to have_http_status(:ok)
      expect(task.reload.status).to eq("closed")
    end

    it "forbids updating a task assigned to someone else" do
      task = Task.create!(title: "Not yours", project: project, assignee: mccoy)

      patch "/api/v1/tasks/#{task.id}", params: { task: { status: "closed" } }, headers: auth_headers(spock)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a non-pm from deleting a task" do
      task = Task.create!(title: "Protected", project: project)

      delete "/api/v1/tasks/#{task.id}", headers: auth_headers(spock)

      expect(response).to have_http_status(:forbidden)
    end

    it "allows the assignee to update title/description/status, but NOT project_id or assignee_id" do
      other_project = Project.create!(name: "Different Project", pm: kirk)
      task = Task.create!(title: "My task", project: project, assignee: spock)

      patch "/api/v1/tasks/#{task.id}",
            params: { task: { title: "Renamed by assignee", project_id: other_project.id, assignee_id: mccoy.id } },
            headers: auth_headers(spock)

      expect(response).to have_http_status(:ok)
      task.reload
      expect(task.title).to eq("Renamed by assignee")   # dozvoljeno polje - promenjeno
      expect(task.project_id).to eq(project.id)             # zabranjeno polje - NIJE promenjeno
      expect(task.assignee_id).to eq(spock.id)                # zabranjeno polje - NIJE promenjeno
    end
  end
end
