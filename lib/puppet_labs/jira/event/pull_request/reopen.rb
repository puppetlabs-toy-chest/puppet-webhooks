require 'puppet_labs/jira/event/pull_request'

require 'puppet_labs/jira/client'
require 'puppet_labs/jira/issue'
require 'puppet_labs/jira/formatter'

# Orchestrate the actions needed to reopen a pull request.
#
# @api private
class PuppetLabs::Jira::Event::PullRequest::Reopen

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
    add_reopened_comment
  end

  private

  def add_reopened_comment
    summary = PuppetLabs::Jira::Formatter.format_pull_request(pull_request)[:summary]
    comment = "Pull request #{pull_request.title}(#{pull_request.action}) reopened by #{pull_request.author}"

    add_comment(summary, comment)
  end

  def add_comment(summary, comment)
    logger.info "Looking up issue with summary #{summary}"

    issue_list = PuppetLabs::Jira::Issue.matching_summary(client, summary)
    if issue_list.size == 0
      logger.error "Could not find issue with summary #{summary}: cannot add comment"
    elsif issue_list.size == 1
      issue = issue_list.first
      logger.info "Adding comment to issue with key #{issue.key}"
      issue.comment(comment)
    else
      logger.warn "Retrieved multiple issues with summary #{summary}. Only commenting on the first one"

      issue = issue_list.first
      logger.info "Adding comment to issue with key #{issue.key}"
      issue.comment(comment)
    end

  rescue JIRA::HTTPError => e
    logger.error "Failed to add comment: #{e.response.body}"
  end
end
