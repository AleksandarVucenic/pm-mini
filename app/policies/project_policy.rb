class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    pm?
  end

  def destroy?
    pm?
  end

  private

  def pm?
    record.pm_id == user.id
  end
end