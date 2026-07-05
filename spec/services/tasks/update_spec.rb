require "rails_helper"

RSpec.describe Tasks::Update do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_update@test.com", password: "12345678") }
  let(:project) { Project.create!(name: "Enterprise Refit", pm: pm) }

  describe "#call" do
    it "persists changes to an existing task" do
      task = Task.create!(title: "Original title", project: project)
      task.title = "Updated title"

      described_class.new(task).call

      expect(task.reload.title).to eq("Updated title")
    end

    it "raises ActiveRecord::RecordInvalid for an invalid update" do
      task = Task.create!(title: "Valid title", project: project)
      task.title = ""

      expect { described_class.new(task).call }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "enforces the 5-open-task limit on reassignment" do
      assignee = User.create!(name: "Spock", email: "spock_update@test.com", password: "12345678")
      5.times { |i| Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open) }
      task = Task.create!(title: "Unassigned", project: project, status: :open)
      task.assign_attributes(assignee: assignee)

      expect { described_class.new(task).call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
