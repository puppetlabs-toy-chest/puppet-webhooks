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
        if (issue = pull_request_issue)
          link_issue(PuppetLabs::Jira::Issue.new(issue))
        else
          create_issue
        end
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

        jira_issue = PuppetLabs::Jira::Issue.new(api.Issue.build)

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

      def pull_request_issue
        pattern = %r[\b#{self.project}-(?:\d+)\b]

        keys = pull_request.title.scan(pattern)

        if (key = keys.first)
          logger.info "Extracted JIRA key #{key} from #{pull_request.title}"
          ::JIRA::Resource::Issue.find(api, key)
        end
      end
    end
  end
end
