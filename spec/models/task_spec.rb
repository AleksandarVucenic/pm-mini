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

end
