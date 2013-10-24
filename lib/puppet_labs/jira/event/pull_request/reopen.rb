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
