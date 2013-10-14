module PuppetLabs
  module Jira

    # Format various structures using Jira formatting
    #
    # @see https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=all
    module Formatter

      # Format a pull request
      #
      # @param pr [PuppetLabs::Github::PullRequest]
      #
      # @return [Hash<String, String>] The formatted fields of a pull request
      def format_pull_request(pr)
        description = <<-DESC.gsub(/^ {10}/, '')
          h2. #{pr.title}

           * Author: #{pr.author_name} <#{pr.author_email}>
           * Company: #{pr.author_company}
           * Github ID: #{jira_url(pr.author, pr.author_html_url)}
           * #{jira_url("Pull Request #{pr.number} Discussion", pr.html_url)}
           * #{jira_url("Pull Request #{pr.number} File Diff", "#{pr.html_url}/files")}

          h2. Pull Request Description
          ----

          #{pr.body}
        DESC

        summary = "Pull Request (#{pr.number}): #{pr.title}"

        {
          :description => description,
          :summary     => summary,
        }
      end
      module_function :format_pull_request

      def jira_url(text, url)
        "[%s|%s]" % [text, url]
      end
      module_function :jira_url
    end
  end
end
