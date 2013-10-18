require 'puppet_labs/jira'

require 'puppet_labs/jira/handler'
require 'puppet_labs/jira/event'

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
    end
  end
end
