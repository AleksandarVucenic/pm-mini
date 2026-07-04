class TaskPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    pm? || assignee?
  end

  def create?
    pm?
  end

  def update?
    pm? || assignee?
  end

  def destroy?
    pm?
  end

  private

  def pm?
    record.project.pm_id == user.id
  end

  def assignee?
    record.assignee_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(
        "tasks.project_id IN (:managed_project_ids) OR tasks.assignee_id = :user_id",
        managed_project_ids: Project.where(pm_id: user.id).select(:id),
        user_id: user.id
      )
    end
  end
end
