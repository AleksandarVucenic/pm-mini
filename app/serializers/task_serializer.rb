class TaskSerializer
  def self.call(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      project: { id: task.project.id, name: task.project.name },
      assignee: task.assignee ? UserSerializer.call(task.assignee) : nil,
      updated_at: task.updated_at
    }
  end
end
