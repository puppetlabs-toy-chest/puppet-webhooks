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
          add_reopened_comment
        else
          logger.warn "#{self.class} unable to handle unknown pull request action #{pull_request.action}"
        end
      end

      private

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def add_reopened_comment
        summary = PuppetLabs::Jira::Formatter.format_pull_request(pull_request)[:summary]
        comment = "Pull request #{pull_request.title}(#{pull_request.action}) reopened by #{pull_request.author}"

        add_comment(summary, comment)
      end

      def add_comment(summary, comment)
        logger.info "Looking up issue with summary #{summary}"

        issue_list = PuppetLabs::Jira::Issue.matching_summary(client, summary)
        if issue_list.size == 0
          logger.error "Could not find issue with summary #{summary}: cannot add comment"
        elsif issue_list.size == 1
          issue = issue_list.first
          logger.info "Adding comment to issue with key #{issue.key}"
          issue.comment(comment)
        else
          logger.warn "Retrieved multiple issues with summary #{summary}. Only commenting on the first one"

          issue = issue_list.first
          logger.info "Adding comment to issue with key #{issue.key}"
          issue.comment(comment)
        end

      rescue JIRA::HTTPError => e
        logger.error "Failed to add comment: #{e.response.body}"
      end
    end
  end
end
