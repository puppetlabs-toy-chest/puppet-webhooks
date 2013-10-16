require 'puppet_labs/jira/event/pull_request'

require 'puppet_labs/jira/client'
require 'puppet_labs/jira/issue'
require 'puppet_labs/jira/formatter'

# Orchestrate the actions needed to open a new pull request.
#
# @api private
class PuppetLabs::Jira::Event::PullRequest::Open

  include PuppetLabs::Jira::Client

  def self.perform(project, pull_request, client = nil)
    obj = new(project, pull_request)
    obj.client = client
    obj.perform
    obj
  end

  def initialize(project, pull_request,  client = nil)
    @project, @pull_request, @client = project, pull_request, client
  end

  attr_accessor :project
  attr_accessor :pull_request

  def perform
    create_or_link
  end

  attr_writer :logger

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def create_or_link
    if (issue = issue_for_pull_request)
      link_issue(PuppetLabs::Jira::Issue.new(issue))
    else
      create_issue
    end
  end

  def link_issue(jira_issue)
    logger.info "Adding pull request link to issue #{jira_issue.key}"

    link_title = "Pull Request: #{pull_request.title}"
    link_icon  = {
      'url16x16' => 'http://github.com/favicon.ico',
      'title'    => 'Pull Request',
    }

    jira_issue.remotelink(
      pull_request.html_url,
      link_title,
      'Github',
      link_icon
    )
  end

  # Generate a new Jira issue based on the given pull request, and attach
  # a link to the pull request
  def create_issue
    logger.info "Creating new issue in project #{self.project}: #{pull_request.title}"

    jira_issue = PuppetLabs::Jira::Issue.build(client)
    formatted = PuppetLabs::Jira::Formatter.format_pull_request(pull_request)

    jira_issue.create(
      self.project,
      formatted[:summary],
      formatted[:description],
      'Task'
    )

    link_issue(jira_issue)
  rescue JIRA::HTTPError => e
    logger.error "Failed to save #{pull_request.title}: #{e.response.body}"
  end

  # Fetch a Jira issue that's associated with a pull request.
  #
  # This searches the title of a pull request for a Jira issue in the
  # related project. If the key is found, a lookup is performed on that
  # key and the issue is returned if found.
  def issue_for_pull_request
    pattern = %r[\b#{self.project}-(?:\d+)\b]

    keys = pull_request.title.scan(pattern)

    if (key = keys.first)
      logger.info "Extracted JIRA key #{key} from #{pull_request.title}"
      ::JIRA::Resource::Issue.find(client, key)
    end
  end
end
