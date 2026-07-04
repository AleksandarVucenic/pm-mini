class ProjectSerializer
  include JSONAPI::Serializer

  attribute :name do |object|
    project_for(object).name
  end

  attribute :pm do |object|
    UserSerializer.embedded(project_for(object).pm)
  end

  attribute :open_tasks_count do |object|
    object.respond_to?(:open_tasks_count) ? object.open_tasks_count.to_i : project_for(object).tasks.open.count
  end

  attribute :closed_tasks_count do |object|
    object.respond_to?(:closed_tasks_count) ? object.closed_tasks_count.to_i : project_for(object).tasks.closed.count
  end

  def self.project_for(object)
    object.respond_to?(:project) ? object.project : object
  end
end
