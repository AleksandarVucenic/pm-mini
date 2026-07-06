class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.boolean :closed, null: false, default: false
      t.references :project, null: false, foreign_key: true
      t.references :assignee, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, [ :project_id, :assignee_id ]
  end
end
