require 'puppet_labs/jira'
require 'puppet_labs/jira/errors'
require 'puppet_labs/jira/event'

require 'puppet_labs/project'

require 'logger'

module PuppetLabs
  module Jira
    class PullRequestHandler < Handler

      attr_accessor :pull_request

      def perform
        logger.info "Running Jira Pull Request handler with action #{pull_request.action}: (#{pull_request.title})"

        case pull_request.action
        when 'opened'
          PuppetLabs::Jira::Event::PullRequest::Open.perform(pull_request, project)
        when 'closed'
          PuppetLabs::Jira::Event::PullRequest::Close.perform(pull_request, project)
        when 'reopened'
          PuppetLabs::Jira::Event::PullRequest::Reopen.perform(pull_request, project)
        else
          logger.warn "#{self.class} unable to handle unknown pull request action #{pull_request.action}"
        end
      end

      private

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def project
        querystr = 'full_name = ? AND jira_project IS NOT NULL'
        result = PuppetLabs::Project.where(querystr, pull_request.full_name).first

        if result
          result.jira_project
        else
          raise PuppetLabs::Jira::NoProjectError, "Project #{pull_request.full_name} doesn't have an associated Jira project"
        end
      end
    end
  end
end
