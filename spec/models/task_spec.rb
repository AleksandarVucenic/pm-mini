require "rails_helper"

RSpec.describe Task, type: :model do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_task@test.com", password: "sigurna123") }
  let(:assignee) { User.create!(name: "Spock", email: "spock_task@test.com", password: "sigurna123") }
  let(:project) { Project.create!(name: "Enterprise Refit", pm: pm) }

  describe "validations" do
    it "is valid with a title and a project" do
      task = Task.new(title: "Fix warp core", project: project)
      expect(task).to be_valid
    end

    it "is invalid without a title" do
      task = Task.new(project: project)
      expect(task).not_to be_valid
    end

    it "is invalid without a project" do
      task = Task.new(title: "Fix warp core")
      expect(task).not_to be_valid
    end

    it "is valid without an assignee (assignee can be blank)" do
      task = Task.new(title: "Fix warp core", project: project, assignee: nil)
      expect(task).to be_valid
    end

    it "defaults to open status" do
      task = Task.create!(title: "Fix warp core", project: project)
      expect(task).to be_open
    end
  end

  describe "the 5 open tasks per assignee per project limit" do
    it "allows exactly 5 open tasks for the same assignee in the same project" do
      5.times do |i|
        Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open)
      end

      expect(Task.where(project: project, assignee: assignee, status: :open).count).to eq(5)
    end

    it "rejects a 6th open task for the same assignee in the same project" do
      5.times do |i|
        Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open)
      end

      sixth_task = Task.new(title: "One too many", project: project, assignee: assignee, status: :open)

      expect(sixth_task).not_to be_valid
      expect(sixth_task.errors[:assignee]).to include("already has 5 open tasks in this project")
    end

    it "allows the 6th task if it is closed, not open" do
      5.times do |i|
        Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open)
      end

      sixth_task = Task.new(title: "Closed task", project: project, assignee: assignee, status: :closed)

      expect(sixth_task).to be_valid
    end

    it "allows a 6th open task if it belongs to a different project" do
      other_project = Project.create!(name: "Voyager Refit", pm: pm)
      5.times do |i|
        Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open)
      end

      task_in_other_project = Task.new(title: "Different project task", project: other_project, assignee: assignee, status: :open)

      expect(task_in_other_project).to be_valid
    end

    it "allows a 6th open task if assigned to a different user" do
      other_user = User.create!(name: "McCoy", email: "mccoy_task@test.com", password: "sigurna123")
      5.times do |i|
        Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open)
      end

      task_for_other_user = Task.new(title: "Different assignee task", project: project, assignee: other_user, status: :open)

      expect(task_for_other_user).to be_valid
    end

    it "does not count the task against itself when updating an existing task" do
      tasks = 5.times.map do |i|
        Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open)
      end

      # Updating one of the 5 existing tasks (e.g. just changing the title) should NOT
      # trip the limit by counting itself as a 6th task.
      expect { tasks.first.update!(title: "Updated title") }.not_to raise_error
    end

    it "allows reassigning a task without hitting the limit if status stays the same open count" do
      5.times do |i|
        Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open)
      end
      task = Task.create!(title: "Unassigned task", project: project, status: :open)

      # Assigning this already-open task to `assignee` would make it a 6th — should fail
      expect { task.update!(assignee: assignee) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
