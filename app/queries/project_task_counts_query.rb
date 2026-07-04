class ProjectTaskCountsQuery
  Result = Struct.new(:project, :open_tasks_count, :closed_tasks_count) do
    def id
      project.id
    end
  end

  def initialize(relation: Project.all)
    @relation = relation
  end

  def call
    projects = relation.includes(:pm).to_a
    project_ids = projects.map(&:id)

    open_counts = Task.where(project_id: project_ids, status: :open).group(:project_id).count
    closed_counts = Task.where(project_id: project_ids, status: :closed).group(:project_id).count

    projects.map do |project|
      Result.new(project, open_counts[project.id] || 0, closed_counts[project.id] || 0)
    end
  end

  private

  attr_reader :relation
end
