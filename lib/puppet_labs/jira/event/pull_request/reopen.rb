require 'puppet_labs/jira/event/pull_request'
require 'puppet_labs/jira/event/pull_request/base'

require 'puppet_labs/jira/issue'

# Orchestrate the actions needed to reopen a pull request.
#
# @api private
class PuppetLabs::Jira::Event::PullRequest::Reopen < PuppetLabs::Jira::Event::PullRequest::Base

  def perform
    add_reopened_comment
  end

  private

  def add_reopened_comment
    if (issue = issue_for_event(pull_request.title, pull_request.identifier))
      comment = "Pull request #{pull_request.title} has been reopened."
      issue.comment(comment)
    else
      logger.warn "Can't comment on pull request reopen event: no issue matches the pull request"
    end
  end
end
