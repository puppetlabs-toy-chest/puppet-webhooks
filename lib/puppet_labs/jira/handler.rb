require 'puppet_labs/jira/client'

module PuppetLabs
  module Jira
    class Handler

      include PuppetLabs::SinatraDJ

      include PuppetLabs::Jira::Client

      def queue(options={:queue => queue_name})
        queue_job(self, options)
      end

      def queue_name
        'jira'
      end

      def project
        ENV['JIRA_PROJECT']
      end
    end
  end
end
