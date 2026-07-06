require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with name, email, password" do
      user = User.new(name: "Kirk", email: "kirk@enterprise.com", password: "password123")
      expect(user).to be_valid
    end
    it "is invalid without name" do
      user = User.new(email: "kirk@enterprise.com", password: "password123")
      expect(user).not_to be_valid
    end

    it "is invalid without email" do
      user = User.new(name: "Kirk", password: "password123")
      expect(user).not_to be_valid
    end
    it "is invalid with a malformed email" do
      user = User.new(name: "Kirk", email: "not-an-email", password: "password123")
      expect(user).not_to be_valid
    end

    it "is invalid with a duplicate email (case insensitive)" do
      User.create!(name: "Kirk", email: "kirk@test.com", password: "password123")
      duplicate = User.new(name: "Spock", email: "KIRK@TEST.COM", password: "password123")
      expect(duplicate).not_to be_valid
    end

    it "is invalid with a password shorter than 6 characters" do
      user = User.new(name: "Ana", email: "ana@test.com", password: "short")
      expect(user).not_to be_valid
    end
  end

  describe "assigned_tasks association" do
    it "nullifies assignee_id on tasks when the user is deleted" do
      pm = User.create!(name: "Kirk", email: "kirk_del@test.com", password: "password123")
      assignee = User.create!(name: "Spock", email: "spock_del@test.com", password: "password123")
      project = Project.create!(name: "Test Project", pm: pm)
      task = Task.create!(title: "Test task", project: project, assignee: assignee)

      assignee.destroy!

      expect(task.reload.assignee_id).to be_nil
    end
  end
end
