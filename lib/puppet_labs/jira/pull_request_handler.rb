require 'puppet_labs/jira/handler'

require 'logger'

module PuppetLabs
  module Jira
    class PullRequestHandler < Handler

      attr_accessor :pull_request

      def perform
        logger.info "Running Jira Pull Request handler with action #{pull_request.action}: (#{pull_request.title})"

        case pull_request.action
        when 'opened'
          create_or_link
        when 'closed'
        when 'reopened'
        else
          # unhandled event, panic
        end
      end

      private

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def create_or_link
        create
      end

      def create
        logger.info "Creating new issue: #{pull_request.title}"

        issue = api.Issue.build

        issue.save!({
          'fields' => {
            'summary'     => pull_request.summary,
            'description' => pull_request.description,
          }
        })
      end
    end
  end
end
