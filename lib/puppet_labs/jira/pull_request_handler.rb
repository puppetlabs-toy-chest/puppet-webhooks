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

      def add_issue_link(issue)
        logger.info "Adding pull request link to existing issue #{issue.key}"

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

        api.post(remotelink_endpoint, remotelink_body.to_json)
      end

      def create_issue
        logger.info "Creating new issue: #{pull_request.title}"

        issue = api.Issue.build

        saved = issue.save({
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

        if not saved
          logger.error "Failed to save #{pull_request.title}: #{issue.attrs['errors']}"
        end
      end
    end
  end
end
