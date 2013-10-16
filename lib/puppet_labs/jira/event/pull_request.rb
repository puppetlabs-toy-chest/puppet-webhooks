require 'puppet_labs/jira/event'

class PuppetLabs::Jira::Event::PullRequest

  require 'puppet_labs/jira/event/pull_request/open'
  require 'puppet_labs/jira/event/pull_request/close'
  require 'puppet_labs/jira/event/pull_request/reopen'

  attr_accessor :pull_request

  def perform
    logger.info "Running Jira Pull Request handler with action #{pull_request.action}: (#{pull_request.title})"

    case pull_request.action
    when 'opened'
      PullRequest::Open.perform(project, pull_request)
    when 'closed'
      PullRequest::Close.perform(project, pull_request)
    when 'reopened'
      PullRequest::Reopen.perform(project, pull_request)
    else
      logger.warn "#{self.class} unable to handle unknown pull request action #{pull_request.action}"
    end
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def project
    ENV['JIRA_PROJECT']
  end

end
