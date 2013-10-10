require 'puppet_labs/jira/api'

module PuppetLabs
  module Jira
    class Handler

      def api
        API.api
      end
    end
  end
end
