require 'puppet_labs/base_trello_job'
require 'puppet_labs/issue'

module PuppetLabs
##
# TrelloIssueJob is responsible for performing the action of updating a
# Trello card based on a bunch of Issue data.  This data generally comes from
# a webhook event.
#
# Instances of this object are meant to be stored with Delayed Job which will
# execute the {perform} instance method at a later point in time.
class TrelloIssueJob < BaseTrelloJob
  attr_accessor :issue

  def card_body
    str = [ "Links: [Issue #{issue.number} Discussion](#{issue.html_url})",
            '',
            issue.body,
    ].join("\n")
  end

  def card_identifier
    "(GH-ISSUE #{issue.repo_name}/#{issue.number})"
  end

  def card_title
    "#{card_identifier} #{issue.title}"
  end

  def queue_name
    'issue'
  end
end
end
