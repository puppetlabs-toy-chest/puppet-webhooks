$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'thor'

require 'puppet_labs/webhook'
require 'puppet_labs/project'

class ProjectConfig < Thor
  namespace :projects

  desc "list", "List existing project configuration"
  def list
    PuppetLabs::Webhook.setup_environment(ENV['RACK_ENV'])

    projects = PuppetLabs::Project.all.map do |project|
      [project.id, project.full_name, project.jira_project, project.jira_labels]
    end

    projects.unshift TABLE_HEADER

    print_table projects
  end

  desc "create REPO_NAME JIRA_PROJECT JIRA_LABELS", "Create a new project definition"
  def create(repo_name, jira_project, jira_labels = '')
    PuppetLabs::Webhook.setup_environment(ENV['RACK_ENV'])

    project = PuppetLabs::Project.new
    project.full_name    = repo_name
    project.jira_project = jira_project
    project.jira_labels  = jira_labels.split /\s*,\s*/
    project.save!

    say "Successfully created new project."
    print_table [
      TABLE_HEADER,
      [project.id, project.full_name, project.jira_project, project.jira_labels]
    ]
  end

  def self.banner(task, namespace = true, subcommand = false)
    "#{basename} #{task.formatted_usage(self, true, subcommand)}"
  end

  TABLE_HEADER = ['ID', 'Full name', 'Jira project', 'Jira labels']
end
