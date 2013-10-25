require 'puppet_labs/jira'

require 'puppet_labs/jira/handler'
require 'puppet_labs/jira/event'
require 'puppet_labs/jira/errors'

require 'logger'

module PuppetLabs
  module Jira
    class CommentHandler < Handler

      attr_accessor :comment

      def perform
        logger.info "Running Jira Comment handler with action #{comment.action}: (#{comment.pull_request.title})"

        case comment.action
        when 'created'
          PuppetLabs::Jira::Event::Comment::Create.perform(comment, project)
        else
          logger.warn "#{self.class} unable to handle unknown comment action #{comment.action}"
        end
      end

      private

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def project
        querystr = 'full_name = ? AND jira_project IS NOT NULL'
        result = PuppetLabs::Project.where(querystr, comment.full_name).first

        if result
          result.jira_project
        else
          raise PuppetLabs::Jira::NoProjectError, "Project #{pull_request.full_name} doesn't have an associated Jira project"
        end
      end
    end
  end
end
