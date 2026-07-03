class ProjectSerializer
  def self.call(project)
    {
      id: project.id,
      name: project.name,
      pm: UserSerializer.call(project.pm),
      open_tasks_count: 0,
      closed_tasks_count: 0
    }
  end
end
