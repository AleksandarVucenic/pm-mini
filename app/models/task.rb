class Task < ApplicationRecord
  belongs_to :project
  belongs_to :assignee, class_name: "User", optional: true

  enum :status, { open: 0, closed: 1 }

  validates :title, presence: true, length: { maximum: 200 }
  validate :assignee_open_task_limit, if: -> { assignee_id.present? && open? }

  private

  def assignee_open_task_limit
    return unless will_save_change_to_assignee_id? || will_save_change_to_status?

    count = Task.where(project_id: project_id, assignee_id: assignee_id, status: :open)
                .where.not(id: id)
                .count

    errors.add(:assignee, "already has 5 open tasks in this project") if count >= 5
  end
end