require "rails_helper"

RSpec.describe TaskQuery do
  let(:pm) { User.create!(name: "Kirk", email: "kirk_tq@test.com", password: "sigurna123") }
  let(:project_a) { Project.create!(name: "Enterprise Refit", pm: pm) }
  let(:project_b) { Project.create!(name: "Voyager Refit", pm: pm) }

  before do
    Task.create!(title: "Fix warp core", project: project_a)
    Task.create!(title: "Repair shields", project: project_a, closed: true)
    Task.create!(title: "Calibrate sensors", project: project_b)
  end

  it "returns all tasks with no filters" do
    expect(described_class.new(params: {}).call.count).to eq(3)
  end

  it "filters by closed=false (open tasks)" do
    result = described_class.new(params: { closed: "false" }).call
    expect(result.count).to eq(2)
  end

  it "filters by closed=true (closed tasks)" do
    result = described_class.new(params: { closed: "true" }).call
    expect(result.count).to eq(1)
  end

  it "filters by project_id" do
    result = described_class.new(params: { project_id: project_a.id }).call
    expect(result.count).to eq(2)
  end

  it "filters by term matching task title" do
    result = described_class.new(params: { term: "warp" }).call
    expect(result.count).to eq(1)
    expect(result.first.title).to eq("Fix warp core")
  end

  it "filters by term matching project name" do
    result = described_class.new(params: { term: "voyager" }).call
    expect(result.count).to eq(1)
    expect(result.first.title).to eq("Calibrate sensors")
  end

  it "is case insensitive" do
    result = described_class.new(params: { term: "WARP" }).call
    expect(result.count).to eq(1)
  end

  it "combines multiple filters" do
    result = described_class.new(params: { closed: "false", project_id: project_a.id }).call
    expect(result.count).to eq(1)
    expect(result.first.title).to eq("Fix warp core")
  end

  it "respects a custom relation passed in (e.g. from policy_scope)" do
    restricted = Task.where(project_id: project_a.id)
    result = described_class.new(relation: restricted, params: {}).call
    expect(result.count).to eq(2)
  end

  it "raises InvalidFilterError for an unknown closed value" do
    expect {
      described_class.new(params: { closed: "maybe" }).call
    }.to raise_error(InvalidFilterError, /'maybe' is not a valid value for closed/)
  end
end
