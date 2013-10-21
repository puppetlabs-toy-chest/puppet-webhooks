require 'puppet_labs/jira/event/comment'

require 'puppet_labs/jira/client'
require 'puppet_labs/jira/issue'
require 'puppet_labs/jira/formatter'

class PuppetLabs::Jira::Event::Comment::Create

  include PuppetLabs::Jira::Client

  def self.perform(comment, project, client = nil)
    obj = new(comment, project, client)
    obj.perform
    obj
  end

  def initialize(comment, project, client = nil)
    @comment = comment
    @project = project
    @client  = client
  end

  attr_accessor :project
  attr_accessor :comment

  def perform
    add_comment
  end

  attr_writer :logger

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def add_comment
    identifier = comment.issue.identifier

    logger.info "Looking up issue with identifier #{identifier}"

    message = <<-COMMENT.gsub(/ {6}/, '')
      #{comment.author_login} commented:

      #{comment.body}
    COMMENT

    if (issue = PuppetLabs::Jira::Issue.matching_webhook_id(client, identifier))
      issue.comment(message)
    else
      logger.warn "Can't comment on github comment event: no issue with webhook identifier #{identifier}"
    end
  end
end
