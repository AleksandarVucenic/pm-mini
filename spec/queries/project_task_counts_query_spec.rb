require "rails_helper"

RSpec.describe ProjectTaskCountsQuery do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_ptcq@test.com", password: "123456789") }
  let(:project_a) { Project.create!(name: "Project A", pm: pm) }
  let(:project_b) { Project.create!(name: "Project B", pm: pm) }

  before do
    Task.create!(title: "Open 1", project: project_a, status: :open)
    Task.create!(title: "Open 2", project: project_a, status: :open)
    Task.create!(title: "Closed 1", project: project_a, status: :closed)
    Task.create!(title: "Open in B", project: project_b, status: :open)
  end

  it "returns correct open and closed counts per project" do
    results = described_class.new.call

    project_a_result = results.find { |r| r.project.id == project_a.id }
    project_b_result = results.find { |r| r.project.id == project_b.id }

    expect(project_a_result.open_tasks_count).to eq(2)
    expect(project_a_result.closed_tasks_count).to eq(1)
    expect(project_b_result.open_tasks_count).to eq(1)
    expect(project_b_result.closed_tasks_count).to eq(0)
  end

  it "returns zero counts for a project with no tasks" do
    empty_project = Project.create!(name: "Empty Project", pm: pm)

    results = described_class.new.call
    empty_result = results.find { |r| r.project.id == empty_project.id }

    expect(empty_result.open_tasks_count).to eq(0)
    expect(empty_result.closed_tasks_count).to eq(0)
  end

  it "respects a custom relation passed in" do
    results = described_class.new(relation: Project.where(id: project_a.id)).call

    expect(results.size).to eq(1)
    expect(results.first.project).to eq(project_a)
  end

  it "exposes an id method that returns the project's id" do
    results = described_class.new(relation: Project.where(id: project_a.id)).call

    expect(results.first.id).to eq(project_a.id)
  end
end
