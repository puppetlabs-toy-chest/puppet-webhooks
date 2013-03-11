require 'puppet_labs/base_trello_job'
require 'puppet_labs/comment'

module PuppetLabs
##
# TrelloCommentJob is responsible for performing the action of updating a
# Trello card based on a bunch of Comment data.  This data generally comes from
# a webhook event.
#
# Instances of this object are meant to be stored with Delayed Job which will
# execute the {perform} instance method at a later point in time.
class TrelloCommentJob < BaseTrelloJob
  attr_accessor :comment

  def card_body
    [
      "#{comment.author_login} wrote:",
      '',
      comment.body,
    ].join("\n")
  end

  def card_identifier
    "(#{card_subidentifier} #{comment.repo_name}/#{comment.issue.number})"
  end

  def card_subidentifier
    comment.pull_request? ? 'PR' : 'GH-ISSUE'
  end

  def card_title
    "#{card_identifier} #{comment.issue.title}"
  end

  def queue_name
    'comment'
  end

  def perform
    name = card_title
    display "Processing: #{name}"
    if card = find_card(name)
      display "Found card #{name} id=#{card.short_id}"
      card.add_comment card_body
      card.save
    else
      display "No card named #{name} found."
    end
    true
  end
end
end
