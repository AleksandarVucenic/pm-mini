class ProjectEmbedSerializer
  include JSONAPI::Serializer

  set_type :project

  attributes :name

  belongs_to :pm, serializer: UserSerializer
end
