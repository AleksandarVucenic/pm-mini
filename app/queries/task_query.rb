class TaskQuery
  def initialize(relation: Task.all, params: {})
    @relation = relation
    @params = params
  end

  def call
    scope = relation.includes(project: :pm, assignee: []).order(updated_at: :desc)
    scope = filter_by_closed(scope)
    scope = filter_by_project(scope)
    scope = filter_by_term(scope)
    scope
  end

  private

  attr_reader :relation, :params

  def filter_by_closed(scope)
    return scope unless params[:closed].present?
    raise InvalidFilterError, "'#{params[:closed]}' is not a valid value for closed" unless %w[true false].include?(params[:closed])

    scope.where(closed: params[:closed] == "true")
  end

  def filter_by_project(scope)
    return scope unless params[:project_id].present?

    scope.where(project_id: params[:project_id])
  end

  def filter_by_term(scope)
    return scope unless params[:term].present?

    sanitized_term = ActiveRecord::Base.sanitize_sql_like(params[:term])
    scope.joins(:project).where(
      "tasks.title LIKE :term OR projects.name LIKE :term",
      term: "%#{sanitized_term}%"
    )
  end
end
