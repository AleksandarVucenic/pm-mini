class TaskSerializer
  include JSONAPI::Serializer

  attributes :title, :description, :closed, :updated_at

  belongs_to :project, serializer: ProjectEmbedSerializer
  belongs_to :assignee, serializer: UserSerializer
end
