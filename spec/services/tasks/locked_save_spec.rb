require "rails_helper"

RSpec.describe Tasks::LockedSave do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_ls@test.com", password: "12345678") }
  let(:assignee) { User.create!(name: "Spock", email: "spock_ls@test.com", password: "12345678") }
  let(:project) { Project.create!(name: "Enterprise Refit", pm: pm) }

  describe "#call" do
    context "with a valid new task" do
      it "persists the task" do
        task = Task.new(title: "Fix warp core", project: project)

        described_class.new(task).call

        expect(task).to be_persisted
      end
    end

    context "with a valid existing task" do
      it "persists the update" do
        task = Task.create!(title: "Original title", project: project)
        task.title = "Updated title"

        described_class.new(task).call

        expect(task.reload.title).to eq("Updated title")
      end
    end

    context "with an invalid task" do
      it "raises ActiveRecord::RecordInvalid" do
        task = Task.new(project: project) # missing required title

        expect { described_class.new(task).call }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not persist the task" do
        task = Task.new(project: project)

        described_class.new(task).call rescue ActiveRecord::RecordInvalid

        expect(task).not_to be_persisted
      end

      it "does not change the task count" do
        task = Task.new(project: project)
        count_before = Task.count

        described_class.new(task).call rescue ActiveRecord::RecordInvalid

        expect(Task.count).to eq(count_before)
      end
    end

    context "when the 5-open-task limit would be exceeded" do
      before do
        5.times { |i| Task.create!(title: "Task #{i}", project: project, assignee: assignee, status: :open) }
      end

      it "raises ActiveRecord::RecordInvalid" do
        sixth = Task.new(title: "One too many", project: project, assignee: assignee, status: :open)

        expect { described_class.new(sixth).call }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not persist the 6th task" do
        sixth = Task.new(title: "One too many", project: project, assignee: assignee, status: :open)

        described_class.new(sixth).call rescue ActiveRecord::RecordInvalid

        expect(Task.where(project: project, assignee: assignee, status: :open).count).to eq(5)
      end

      it "acquires a lock on the project before saving" do
        task = Task.new(title: "Fix warp core", project: project)
        expect(task.project).to receive(:lock!).and_call_original

        described_class.new(task).call rescue nil
      end
    end
  end
end
