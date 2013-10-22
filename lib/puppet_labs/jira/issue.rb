require 'puppet_labs/jira'

require 'forwardable'

module PuppetLabs
  module Jira

    # This wraps access to creating and modifying JIRA issues, so that calling
    # classes don't have to handle the specifics of the JIRA API and markup
    # format.
    class Issue

      # Generate a new issue
      #
      # This method should be used when generating a new issue so that the issue
      # is always associated with a pull request.
      #
      # @param client [JIRA::Client]
      # @param project [String] The project to associate this issue with
      def self.build(client, project)
        new(client.Issue.build, project)
      end

      extend Forwardable
      def_delegator :@issue, :key

      # @!attribute [rw] issuetype
      #   @return [String] The Jira issuetype for this issue
      #   @see https://confluence.atlassian.com/display/JIRA/What+is+an+Issue#WhatisanIssue-IssueType
      #   @see https://confluence.atlassian.com/display/JIRA/Defining+'Issue+Type'+Field+Values
      attr_accessor :issuetype

      # @!attribute [rw] project
      #   @return [String] The project ID that this issue belongs to
      attr_reader :project

      # @return [JIRA::Resource::Issue] The wrapped jira issue
      def wrapped
        @issue
      end

      # @param issue [JIRA::Resource::Issue]
      def initialize(issue, project = nil)
        @issue   = issue
        @project = project

        @issuetype = 'Task'
      end

      # Create a new issue in a given JIRA project
      #
      # @param summary [String] The issue summary
      # @param description [String] The issue description
      def create(summary, description)
        @issue.save!({
          'fields' => {
            'project'     => {'key' => @project},
            'summary'     => summary,
            'description' => description,
            'issuetype'   => {'name' => @issuetype},
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
      # @param comment_body [String]
      # @return [void]
      def comment(comment_body)
        comment = @issue.comments.build
        comment.save!({'body' => comment_body})
      end

      # Look up an issue based on a webhook-id field embedded in an issue description
      #
      # This assumes that only one issue will ever have this exact string. If
      # multiple issues have 'webhooks-id: checksum' (for instance if a
      # description is copied then it'll fail. If this assertion fails, we
      # probably can't distinguish issues by any other way, so we're already
      # out of luck.
      #
      # @param client [JIRA::Client] The API client to use for the query
      # @param project [String] The project to search
      # @param sum [String] The MD5 used to identify the issue
      #
      def self.matching_webhook_id(client, project, sum)
        query = %{description ~ "webhooks-id:+#{sum} and project = '#{project}'"}

        jql(client, query).first
      end

      # @api private
      #
      # @see https://confluence.atlassian.com/display/JIRA/Advanced+Searching+Functions#AdvancedSearchingFunctions-characters
      JQL_RESERVED_CHARACTERS = ':()'

      # @api private
      #
      # @param client [JIRA::Client] The API client to use for the query
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
