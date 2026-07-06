require "rails_helper"

RSpec.describe Project, type: :model do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_test@test.com", password: "password123") }

  describe "validations" do
    it "is valid with a name and a pm" do
      project = Project.new(name: "Enterprise Refit", pm: pm)
      expect(project).to be_valid
    end

    it "is invalid without a name" do
      project = Project.new(pm: pm)
      expect(project).not_to be_valid
    end

    it "is invalid without a pm" do
      project = Project.new(name: "Enterprise Refit")
      expect(project).not_to be_valid
    end

    it "is invalid with a name longer than 150 characters" do
      project = Project.new(name: "a" * 151, pm: pm)
      expect(project).not_to be_valid
    end
  end

  describe "dependent destroy" do
    it "destroys associated tasks when the project is deleted" do
      project = Project.create!(name: "Enterprise Refit", pm: pm)
      Task.create!(title: "Fix warp core", project: project)

      expect { project.destroy! }.to change(Task, :count).by(-1)
    end
  end

  describe "pm restriction" do
    it "prevents deleting a user who is PM of a project" do
      Project.create!(name: "Enterprise Refit", pm: pm)

      expect { pm.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end
end
