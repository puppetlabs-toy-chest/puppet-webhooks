require 'puppet_labs/trello/trello_pull_request_job'
require 'puppet_labs/github/controller'

require 'puppet_labs/jira'

module PuppetLabs
module Github
class PullRequestController < Controller
  attr_reader :pull_request

  def initialize(options = {})
    super(options)
    if pull_request = options[:pull_request]
      @pull_request = pull_request
    end

    @outputs = outputs_from_env
  end

  attr_accessor :outputs

  ##
  # run processes the pull request and queues up a pull request job.
  #
  # @return [Array] containing the Sinatra route style [status, headers_hsh, body_hsh]
  def run
    messages = {'outputs' => outputs}

    jobs = []
    if outputs.include? 'trello'
      output = run_trello
      messages['trello'] = output
    end

    if outputs.include? 'jira'
      output = run_jira
      messages['jira'] = output
    end

    return [ACCEPTED, {}, messages]
  end

  private

  def run_trello
    job = nil
    case pull_request.action
    when "opened"
      job = PuppetLabs::Trello::TrelloPullRequestJob.new
    when "reopened"
      job = PuppetLabs::Trello::TrelloPullRequestReopenedJob.new
    when "closed"
      job = PuppetLabs::Trello::TrelloPullRequestClosedJob.new
    else
      logger.info "Ignoring pull request #{pull_request.repo_name}/#{pull_request.number}: action #{pull_request.action} is unhandled"
      return {'trello' => {'status' => 'failed', 'errors' => 'unhandled action'}}
    end

    enqueue_job(job)
  end

  def run_jira
    job = PuppetLabs::Jira::PullRequestHandler.new
    enqueue_job(job)
  end

  def enqueue_job(job)
    job.pull_request = @pull_request
    delayed_job = job.queue

    logger.info "Queued #{job.class} (#{pull_request.repo_name}/#{pull_request.number}) as job #{delayed_job.id}"
    {
      'status'     => 'ok',
      'job_id'     => delayed_job.id,
      'queue'      => delayed_job.queue,
      'priority'   => delayed_job.priority,
      'created_at' => delayed_job.created_at,
    }
  end

  # Determine which event outputs should be used, based on the environment.
  # Defaults to trello.
  #
  def outputs_from_env
    str = (ENV['GITHUB_EVENT_OUTPUTS'] || 'trello')

    str.split(/,/).map(&:strip)
  end
end
end
end
