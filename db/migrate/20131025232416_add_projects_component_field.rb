class AddProjectsComponentField < ActiveRecord::Migration
  def up
    change_table :projects do |t|
      t.string :jira_components
    end
  end

  def down
    change_table :projects do |t|
      t.remove :jira_components
    end
  end
end
