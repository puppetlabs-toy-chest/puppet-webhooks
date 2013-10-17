require 'puppet_labs/trello/trello_comment_job'
require 'puppet_labs/github/controller'

require 'puppet_labs/jira/event/comment'

module PuppetLabs
module Github
class CommentController < Controller
  attr_reader :comment

  def initialize(options = {})
    super(options)
    @comment = options[:comment]
  end

  ##
  # run processes the comment and queues up an appropriate job.
  #
  # @return [Array] containing the Sinatra route style [status, headers_hsh, body_hsh]
  def run
    messages = {'outputs' => outputs}

    if outputs.include? 'trello'
      messages['trello'] = enqueue_trello
    end

    if outputs.include? 'jira'
      messages['jira'] = enqueue_jira
    end

    return [ACCEPTED, {}, messages]
  end

  def enqueue_job(job, event)
    job.comment = event
    super
  end

  private

  def enqueue_trello
    case comment.action
    when "created"
      job = PuppetLabs::Trello::TrelloCommentJob.new
      enqueue_job(job, comment)
    else
      logger.info "Ignoring comment on #{comment.repo_name}/#{comment.issue.number} because the action is #{comment.action}."
      {'status' => 'failed', 'message' => 'Action has been ignored.'}
    end
  end

  def enqueue_jira
    job = PuppetLabs::Jira::CommentHandler.new
    enqueue_job(job, comment)
  end
end
end
end
