require 'puppet_labs/jira/event/pull_request'

require 'puppet_labs/jira/client'
require 'puppet_labs/jira/issue'
require 'puppet_labs/jira/formatter'

# Orchestrate the actions needed to close a pull request.
#
# @api private
class PuppetLabs::Jira::Event::PullRequest::Close

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
    add_closed_comment
  end

  attr_writer :logger

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end


  def add_closed_comment
    identifier = PuppetLabs::Jira::Formatter.pull_request_id(pull_request)

    logger.info "Looking up issue with identifier #{identifier}"

    if (issue = PuppetLabs::Jira::Issue.matching_webhook_id(client, identifier))
      comment = "Pull request #{pull_request.title} has been closed."
      issue.comment(comment)
    else
      logger.warn "Can't comment on pull request close event: no issue with webhook identifier #{identifier}"
    end
  end
end
