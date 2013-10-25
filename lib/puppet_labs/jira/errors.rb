module PuppetLabs
  module Jira
    class JiraError < StandardError; end

    class NoProjectError < JiraError; end
    class APIError < JiraError; end
  end
end
