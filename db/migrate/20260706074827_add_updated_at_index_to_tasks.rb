class AddUpdatedAtIndexToTasks < ActiveRecord::Migration[8.1]
  def change
    add_index :tasks, :updated_at
  end
end
