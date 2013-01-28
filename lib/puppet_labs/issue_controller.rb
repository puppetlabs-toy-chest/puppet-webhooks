require 'puppet_labs/trello_issue_job'
require 'puppet_labs/controller'

module PuppetLabs
class IssueController < Controller
  attr_reader :issue,
    :request,
    :logger

  def initialize(options = {})
    super(options)
    if issue = options[:issue]
      @issue = issue
    end
  end

  ##
  # run processes the issue and queues up an issue job.
  #
  # @return [Array] containing the Sinatra route style [status, headers_hsh, body_hsh]
  def run
    case issue.action
    when "opened"
      job = PuppetLabs::TrelloIssueJob.new
      job.issue = issue
      delayed_job = job.queue
      logger.info "Successfully queued up opened issue #{issue.repo_name}/#{issue.number} as job #{delayed_job.id}"
      body = {
        'job_id' => delayed_job.id,
        'queue' => delayed_job.queue,
        'priority' => delayed_job.priority,
        'created_at' => delayed_job.created_at,
      }
      return [ACCEPTED, {}, body]
    else
      logger.info "Ignoring issue #{issue.repo_name}/#{issue.number} because the action is #{issue.action}."
      body = { 'message' => 'Action has been ignored.' }
      return [OK, {}, body]
    end
  end
end
end
