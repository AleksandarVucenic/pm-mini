class ProjectEmbedSerializer
  include JSONAPI::Serializer

  set_type :project

  attributes :name

  attribute :pm do |project|
    UserSerializer.embedded(project.pm)
  end
end
