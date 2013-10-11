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
        if (issue = pull_request_issue)
          logger.info "Adding pull request link to existing issue #{issue.key}"
          add_issue_link(issue)
        else
          logger.info "Creating new issue in project #{self.project}: #{pull_request.title}"
          create_issue
        end
      end

      def add_issue_link(issue)

        remotelink_body = {
          'application' => {
            'name' => 'Github'
          },
          'relationship' => 'relates to',
          'object' => {
            'url'   => pull_request.html_url,
            'title' => "Github Pull Request: #{pull_request.title}",
            'icon'  => {
              'url16x16' => 'http://github.com/favicon.ico',
              'title'    => 'Github'
            }
          }
        }

        remotelink_endpoint = issue.url + '/remotelink'

        logger.info "Linking Jira issue to Github pull request"
        api.post(remotelink_endpoint, remotelink_body.to_json)
      end

      def create_issue

        issue = api.Issue.build

        issue.save!({
          'fields' => {
            'summary' => pull_request.summary,
            'description' => pull_request.description,
            'project' => {
              'key' => self.project,
            },
            'issuetype' => {
              'name' => 'Task',
            }
          }
        })

        add_issue_link(issue)
      rescue JIRA::HTTPError => e
        logger.error "Failed to save #{pull_request.title}: #{e.response['errors']}"
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
