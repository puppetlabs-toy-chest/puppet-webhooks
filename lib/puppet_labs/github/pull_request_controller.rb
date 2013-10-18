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
  end

  ##
  # run processes the pull request and queues up a pull request job.
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

  private

  def enqueue_trello
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
      return {'status' => 'failed', 'errors' => 'unhandled action'}
    end

    enqueue_job(job, @pull_request)
  end

  def enqueue_jira
    job = PuppetLabs::Jira::PullRequestHandler.new
    enqueue_job(job, @pull_request)
  end

  def enqueue_job(job, event)
    job.pull_request = @pull_request
    super
  end
end
end
end
