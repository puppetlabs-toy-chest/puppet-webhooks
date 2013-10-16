require 'puppet_labs/jira'

require 'forwardable'

module PuppetLabs
  module Jira

    # This wraps access to creating and modifying JIRA issues, so that calling
    # classes don't have to handle the specifics of the JIRA API and markup
    # format.
    class Issue

      def self.build(client)
        new(client.Issue.build)
      end

      def initialize(issue)
        @issue = issue
      end

      def wrapped
        @issue
      end

      extend Forwardable
      def_delegator :@issue, :key

      # Create a new issue in a given JIRA project
      #
      # @param project [String] The project key
      # @param summary [String] The issue summary
      # @param description [String] The issue description
      # @param issuetype [String] The issue type
      def create(project, summary, description, issuetype)
        @issue.save!({
          'fields' => {
            'project'     => {'key' => project},
            'summary'     => summary,
            'description' => description,
            'issuetype'   => {'name' => issuetype},
          }
        })
      end

      # Add a remotelink to an existing issue
      #
      # @todo make this idempotent
      #
      # @param url [String]
      # @param title [String]
      # @param application [String] The name of the application that the link references
      # @param icon [Hash<String, String>] An optional hash of parameters for
      #   the URL icon
      def remotelink(url, title, application, icon = {})

        body = {
          'application' => {'name' => application},
          'relationship' => 'relates to',
          'object' => {
            'url'   => url,
            'title' => title,
            'icon'  => icon,
          }
        }

        endpoint = @issue.url + '/remotelink'
        @issue.client.post(endpoint, body.to_json)
      end

      # Add a comment to an existing issue
      #
      # @todo make this idempotent
      #
      # @param comment_body [String]
      # @return [void]
      def comment(comment_body)
        comment = @issue.comments.build
        comment.save!({'body' => comment_body})
      end

      # Retrieve all issues matching a given summary
      #
      # @param client [JIRA::Client]
      # @param summary [String] The string to be used for the JQL query
      def self.matching_summary(client, summary)
        query = %{summary ~ "#{summary}"}

        jql(client, query)
      end

      # Look up an issue based on a webhook-id field embedded in an issue description
      #
      # This assumes that only one issue will ever have this exact string. If
      # multiple issues have 'webhooks-id: checksum' (for instance if a
      # description is copied then it'll fail. If this assertion fails, we
      # probably can't distinguish issues by any other way, so we're already
      # out of luck.
      #
      # @param sum [String] The MD5 used to identify the issue
      def self.matching_webhook_id(client, sum)
        query = %{description ~ "webhooks-id:+#{sum}"}

        jql(client, query).first
      end

      # @api private
      #
      # @see https://confluence.atlassian.com/display/JIRA/Advanced+Searching+Functions#AdvancedSearchingFunctions-characters
      JQL_RESERVED_CHARACTERS = ':()'

      # @api private
      #
      # @param client [JIRA::Client]
      # @param query [String] The JQL query to run.
      def self.jql(client, query)
        escape_regex = Regexp.new("[#{JQL_RESERVED_CHARACTERS}]")

        # Each JQL reserved character must be escaped, but they have to be
        # escaped with two backslashes, and that has to be double escaped in
        # the ruby string. Furthermore, ruby explodes when you try to juxtapose
        # '\\' and '\1'.
        query = query.gsub(escape_regex) { |escapee| '\\\\' + escapee }

        JIRA::Resource::Issue.jql(client, query).map { |issue| new(issue) }
      end
    end
  end
end
