class Tasks::LockedSave
  def initialize(task)
    @task = task
  end

  def call
    ActiveRecord::Base.transaction do
      task.project.lock!
      task.save!
    end
  end

  private

  attr_reader :task
end
