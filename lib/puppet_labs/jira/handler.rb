require 'puppet_labs/jira/client'
require 'puppet_labs/delayable'

module PuppetLabs
  module Jira
    class Handler
      include PuppetLabs::Jira::Client

      include PuppetLabs::Delayable

      def project
        ENV['JIRA_PROJECT']
      end
    end
  end
end
