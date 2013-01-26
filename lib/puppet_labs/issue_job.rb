require 'puppet_labs/job'
require 'puppet_labs/issue'

module PuppetLabs
  ##
  # IssueJob is responsible for performing the action of updating a
  # Trello card based on a bunch of Issue data.  This data generally
  # comes from a webhook event.
  #
  # Instances of this object are meant to be stored with Delayed Job
class IssueJob < Job
  attr_accessor :issue

  def card_body
    str = [ "Links: [Issue #{issue.number} Discussion](#{issue.html_url})",
            '',
            issue.body,
    ].join("\n")
  end

  def card_title
    "(GH-ISSUE #{issue.repo_name}/#{issue.number}) #{issue.title}"
  end

  def queue_name
    'issue'
  end
end

end
