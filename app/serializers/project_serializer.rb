class ProjectSerializer
  include JSONAPI::Serializer

  attributes :name, :open_tasks_count, :closed_tasks_count

  belongs_to :pm, serializer: UserSerializer
end
