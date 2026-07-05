class Tasks::Base
  def initialize(task)
    @task = task
  end

  private

  attr_reader :task

  def persist!
    ActiveRecord::Base.transaction do
      task.project.lock!
      check_open_task_limit!
      task.save!
    end
  end

  def check_open_task_limit!
    return unless task.assignee_id.present? && task.open?
    return unless task.will_save_change_to_assignee_id? || task.will_save_change_to_status?

    count = Task.where(project_id: task.project_id, assignee_id: task.assignee_id, status: :open)
                .where.not(id: task.id)
                .count

    if count >= 5
      task.errors.add(:assignee, "already has 5 open tasks in this project")
      raise ActiveRecord::RecordInvalid.new(task)
    end
  end
end
