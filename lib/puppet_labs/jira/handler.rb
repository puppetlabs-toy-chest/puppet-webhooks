require 'puppet_labs/jira/api'

module PuppetLabs
  module Jira
    class Handler

      include PuppetLabs::SinatraDJ

      include PuppetLabs::Jira::API

      def queue(options={:queue => queue_name})
        queue_job(self, options)
      end

      def queue_name
        'jira'
      end
    end
  end
end
