require 'puppet_labs/jira/event/pull_request'

require 'puppet_labs/jira/client'
require 'puppet_labs/jira/issue'
require 'puppet_labs/jira/formatter'

# Orchestrate the actions needed to reopen a pull request.
#
# @api private
class PuppetLabs::Jira::Event::PullRequest::Reopen

  include PuppetLabs::Jira::Client

  def self.perform(pull_request, project, client = nil)
    obj = new(pull_request, project, client)
    obj.perform
    obj
  end

  def initialize(pull_request, project, client = nil)
    @pull_request = pull_request
    @project      = project
    @client       = client
  end

  attr_accessor :project
  attr_accessor :pull_request

  def perform
    add_reopened_comment
  end

  attr_writer :logger

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def add_reopened_comment
    identifier = pull_request.identifier

    logger.info "Looking up issue with identifier #{identifier}"

    if (issue = PuppetLabs::Jira::Issue.matching_webhook_id(client, project, identifier))
      comment = "Pull request #{pull_request.title} has been reopened."
      issue.comment(comment)
    else
      logger.warn "Can't comment on pull request reopen event: no issue with webhook identifier #{identifier}"
    end
  end
end
