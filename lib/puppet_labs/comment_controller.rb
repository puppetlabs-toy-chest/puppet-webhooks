require 'puppet_labs/trello_comment_job'
require 'puppet_labs/controller'

module PuppetLabs
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
      job = PuppetLabs::TrelloCommentJob.new
    else
      logger.info "Ignoring comment on #{comment.repo_name}/#{comment.issue.number} because the action is #{comment.action}."
      body = { 'message' => 'Action has been ignored.' }
      return [OK, {}, body]
    end

    job.comment = comment
    delayed_job = job.queue
    logger.info "Successfully queued up the created comment on #{comment.repo_name}/#{comment.issue.number} as job #{delayed_job.id}"
    body = {
      'job_id' => delayed_job.id,
      'queue' => delayed_job.queue,
      'priority' => delayed_job.priority,
      'created_at' => delayed_job.created_at,
    }
    return [ACCEPTED, {}, body]
  end
end
end
