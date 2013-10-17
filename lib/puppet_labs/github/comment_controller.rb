require 'puppet_labs/trello/trello_comment_job'
require 'puppet_labs/github/controller'

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
    case comment.action
    when "created"
      job = PuppetLabs::Trello::TrelloCommentJob.new
    else
      logger.info "Ignoring comment on #{comment.repo_name}/#{comment.issue.number} because the action is #{comment.action}."
      body = { 'message' => 'Action has been ignored.' }
      return [OK, {}, body]
    end

    body = enqueue_job(job, comment)

    return [ACCEPTED, {}, body]
  end

  def enqueue_job(job, event)
    job.comment = event
    super
  end
end
end
end
