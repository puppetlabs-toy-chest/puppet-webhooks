require 'puppet_labs/jira'

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
          add_closed_comment
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

      def create_or_link
        if (issue = issue_for_pull_request)
          link_issue(PuppetLabs::Jira::Issue.new(issue))
        else
          create_issue
        end
      end

      def add_closed_comment
        summary = PuppetLabs::Jira::Formatter.format_pull_request(pull_request)[:summary]
        comment = "Pull request #{pull_request.title}(#{pull_request.action}) closed by #{pull_request.author}"

        add_comment(summary, comment)
      end

      def add_reopened_comment
        summary = PuppetLabs::Jira::Formatter.format_pull_request(pull_request)[:summary]
        comment = "Pull request #{pull_request.title}(#{pull_request.action}) reopened by #{pull_request.author}"

        add_comment(summary, comment)
      end

      def link_issue(jira_issue)
        logger.info "Adding pull request link to issue #{jira_issue.key}"

        link_title = "Pull Request: #{pull_request.title}"
        link_icon  = {
          'url16x16' => 'http://github.com/favicon.ico',
          'title'    => 'Pull Request',
        }

        jira_issue.remotelink(
          pull_request.html_url,
          link_title,
          'Github',
          link_icon
        )
      end

      def create_issue
        logger.info "Creating new issue in project #{self.project}: #{pull_request.title}"

        jira_issue = PuppetLabs::Jira::Issue.new(client.Issue.build)
        formatted = PuppetLabs::Jira::Formatter.format_pull_request(pull_request)

        jira_issue.create(
          self.project,
          formatted[:summary],
          formatted[:description],
          'Task'
        )

        link_issue(jira_issue)
      rescue JIRA::HTTPError => e
        logger.error "Failed to save #{pull_request.title}: #{e.response.body}"
      end

      def issue_for_pull_request
        pattern = %r[\b#{self.project}-(?:\d+)\b]

        keys = pull_request.title.scan(pattern)

        if (key = keys.first)
          logger.info "Extracted JIRA key #{key} from #{pull_request.title}"
          ::JIRA::Resource::Issue.find(client, key)
        end
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
