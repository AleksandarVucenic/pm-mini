class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.references :project, null: false, foreign_key: true
      t.references :assignee, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, :title
    add_index :tasks, :status
    add_index :tasks, [ :project_id, :assignee_id, :status ]
  end
end
