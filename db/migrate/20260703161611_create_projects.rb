class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.references :pm, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
