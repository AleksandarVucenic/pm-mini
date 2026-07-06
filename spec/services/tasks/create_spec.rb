require "rails_helper"

RSpec.describe Tasks::Create do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_create@test.com", password: "12345678") }
  let(:project) { Project.create!(name: "Enterprise Refit", pm: pm) }

  describe "#call" do
    it "persists a new task" do
      task = Task.new(title: "Fix warp core", project: project)

      described_class.new(task).call

      expect(task).to be_persisted
    end

    it "raises ActiveRecord::RecordInvalid for an invalid task" do
      task = Task.new(project: project)

      expect { described_class.new(task).call }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "enforces the 5-open-task limit" do
      assignee = User.create!(name: "Spock", email: "spock_create@test.com", password: "12345678")
      5.times { |i| Task.create!(title: "Task #{i}", project: project, assignee: assignee) }
      sixth = Task.new(title: "One too many", project: project, assignee: assignee)

      expect { described_class.new(sixth).call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
