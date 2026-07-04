class TaskSerializer
  include JSONAPI::Serializer

  attributes :title, :description, :status, :updated_at

  attribute :project do |task|
    { id: task.project.id, name: task.project.name }
  end

  attribute :assignee do |task|
    task.assignee ? UserSerializer.embedded(task.assignee) : nil
  end
end
