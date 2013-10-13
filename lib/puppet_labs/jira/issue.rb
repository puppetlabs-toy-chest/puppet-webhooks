require 'puppet_labs/jira'

require 'forwardable'

module PuppetLabs
  module Jira

    # This wraps access to creating and modifying JIRA issues, so that calling
    # classes don't have to handle the specifics of the JIRA API and markup
    # format.
    class Issue

      def initialize(issue)
        @issue = issue
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
      # @todo make this idempotent
      def comment

      end

      # Retrieve all issues matching a given summary
      #
      # @param client [JIRA::Client]
      # @param summary [String] The string to be used for the JQL query
      def self.matching_summary(client, summary)
        query = %{summary ~ "#{summary}"}
        JIRA::Resource::Issue.jql(client, query)
      end
    end
  end
end
