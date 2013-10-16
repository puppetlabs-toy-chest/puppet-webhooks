require 'puppet_labs/jira'
require 'puppet_labs/jira/event'

require 'logger'

module PuppetLabs
  module Jira
    class PullRequestHandler < Handler

      attr_accessor :pull_request

      def perform
        logger.info "Running Jira Pull Request handler with action #{pull_request.action}: (#{pull_request.title})"

        case pull_request.action
        when 'opened'
          Jira::Event::PullRequest::Open.perform(project, pull_request)
        when 'closed'
          Jira::Event::PullRequest::Close.perform(project, pull_request)
        when 'reopened'
          Jira::Event::PullRequest::Reopen.perform(project, pull_request)
        else
          logger.warn "#{self.class} unable to handle unknown pull request action #{pull_request.action}"
        end
      end

      private

      def logger
        @logger ||= Logger.new(STDOUT)
      end

    end
  end
end
