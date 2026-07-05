class Tasks::Base
  def initialize(task)
    @task = task
  end

  private

  attr_reader :task

  def persist!
    ActiveRecord::Base.transaction do
      task.project.lock!
      task.save!
    end
  end
end
