class ProjectSerializer
  include JSONAPI::Serializer

  attribute :name do |object|
    project_for(object).name
  end

  attribute :pm do |object|
    UserSerializer.embedded(project_for(object).pm)
  end

  attribute :open_tasks_count do |object|
    object.open_tasks_count.to_i
  end

  attribute :closed_tasks_count do |object|
    object.closed_tasks_count.to_i
  end

  def self.project_for(object)
    object.respond_to?(:project) ? object.project : object
  end
end
