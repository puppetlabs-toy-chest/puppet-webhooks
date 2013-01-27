require 'puppet_labs/pull_request_job'
require 'puppet_labs/controller'

module PuppetLabs
class PullRequestController < Controller
  NO_CONTENT = 204
  ACCEPTED = 202
  OK = 200

  attr_reader :pull_request,
    :request,
    :logger

  def initialize(options = {})
    super(options)
    if pull_request = options[:pull_request]
      @pull_request = pull_request
    end
  end

  ##
  # run processes the pull request and queues up a pull request job.
  #
  # @return [Array] containing the Sinatra route style [status, headers_hsh, body_hsh]
  def run
    case pull_request.action
    when "opened"
      job = PuppetLabs::PullRequestJob.new
    when "reopened"
      job = PuppetLabs::PullRequestReopenedJob.new
    when "closed"
      job = PuppetLabs::PullRequestClosedJob.new
    else
      logger.info "Ignoring pull request #{pull_request.repo_name}/#{pull_request.number} because the action is #{pull_request.action}."
      body = { 'message' => 'Action has been ignored.' }
      return [OK, {}, body]
    end

    job.pull_request = pull_request
    delayed_job = job.queue
    logger.info "Successfully queued up #{job.class} (#{pull_request.repo_name}/#{pull_request.number}) as job #{delayed_job.id}"
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
