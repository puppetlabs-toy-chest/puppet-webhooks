class CreateProjects < ActiveRecord::Migration
  def up
    create_table :projects do |t|
      t.string :full_name
      t.string :jira_project
      t.string :jira_labels
    end
  end

  def down
    drop_table :projects
  end
end
