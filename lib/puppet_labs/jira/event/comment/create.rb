require 'puppet_labs/jira/event/comment'

require 'puppet_labs/jira/client'
require 'puppet_labs/jira/issue'
require 'puppet_labs/jira/formatter'
require 'puppet_labs/jira/issue_matcher'

class PuppetLabs::Jira::Event::Comment::Create

  include PuppetLabs::Jira::Client
  include PuppetLabs::Jira::IssueMatcher

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

  # @!attribute [rw] project
  #   @return [PuppetLabs::Project]
  attr_accessor :project

  # @!attribute [rw] comment
  #   @return [PuppetLabs::Github::Comment]
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
    title = comment.issue.title
    identifier = comment.issue.identifier

    message = <<-COMMENT.gsub(/ {6}/, '')
      #{comment.author_login} commented:

      #{comment.body}
    COMMENT

    if (issue = issue_for_event(title, identifier))
      issue.comment(message)
    else
      logger.warn "Can't comment on github comment event: no issue with webhook identifier #{identifier}"
    end
  end
end
