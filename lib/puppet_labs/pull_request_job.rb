require 'puppet_labs/job'
require 'puppet_labs/pull_request'

module PuppetLabs
  ##
  # PullRequestJob is responsible for performing the action of updating a
  # Trello card based on a bunch of Pull Request data.  This data generally
  # comes from a webhook event.
  #
  # Instances of this object are meant to be stored with Delayed Job
class PullRequestJob < Job
  attr_accessor :pull_request

  def card_body
    pr = pull_request
    str = [ "Links: [Pull Request #{pr.number} Discussion](#{pr.html_url}) and",
            "[File Diff](#{pr.html_url}/files)",
            '',
            pr.body,
    ].join("\n")
  end

  def card_title
    pr = pull_request
    "(PR #{pr.repo_name}/#{pr.number}) #{pr.title}"
  end

  def queue_name
    'pull_request'
  end
end

class PullRequestClosedJob < PullRequestJob
  def perform
    display "FIXME cannot perform any actions when a pull request is closed"
  end
end

class PullRequestReopenedJob < PullRequestJob
  def perform
    display "FIXME cannot perform any actions when a pull request is reopened"
  end
end

end
