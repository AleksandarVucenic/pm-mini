require "rails_helper"

RSpec.describe Project, type: :model do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_test@test.com", password: "12345678") }

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

  describe "associations" do
    it "belongs to a pm" do
      project = Project.create!(name: "Enterprise Refit", pm: pm)
      expect(project.pm).to eq(pm)
    end
  end
end