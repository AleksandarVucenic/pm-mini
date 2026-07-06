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

    describe "assignee open task limit" do
      before do
        5.times { |i| Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open) }
      end

      it "is invalid when assignee already has 5 open tasks and a new open task is assigned" do
        task = Task.new(title: "One too many", project: project, assignee: assignee, status: :open)
        expect(task).not_to be_valid
        expect(task.errors[:assignee]).to be_present
      end

      it "blocks re-opening a closed task when assignee is at the limit" do
        closed = Task.create!(title: "Was closed", project: project, assignee: assignee, status: :closed)
        closed.status = :open
        expect(closed).not_to be_valid
      end

      it "allows changing the title without triggering the limit check" do
        task = Task.where(project: project, assignee: assignee, status: :open).first
        task.title = "Renamed"
        expect(task).to be_valid
      end

      it "allows closing one of the open tasks even when at the limit" do
        task = Task.where(project: project, assignee: assignee, status: :open).last
        task.status = :closed
        expect(task).to be_valid
      end
    end
  end
end
