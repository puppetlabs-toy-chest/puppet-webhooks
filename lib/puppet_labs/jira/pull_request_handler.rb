require 'puppet_labs/jira/handler'

require 'logger'

module PuppetLabs
  module Jira
    class PullRequestHandler < Handler

      attr_accessor :pull_request

      def perform
        logger.info "Running Jira Pull Request handler with action #{pull_request.action}: (#{summary})"

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
        logger.info "Creating new issue: #{summary}"

        issue = api.Issue.build

        issue.save!({
          'fields' => {
            'summary'     => summary,
            'description' => description,
          }
        })
      end

      ## - this all should be extracted

      def summary
        pr = @pull_request
        "Pull Request #{pr.number}: #{pr.title} [#{pr.author_name}]"
      end

    end
  end
end
