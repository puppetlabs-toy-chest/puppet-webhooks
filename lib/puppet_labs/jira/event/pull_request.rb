require 'puppet_labs/jira/event'

module PuppetLabs::Jira::Event::PullRequest

  require 'puppet_labs/jira/event/pull_request/open'
  require 'puppet_labs/jira/event/pull_request/close'
  require 'puppet_labs/jira/event/pull_request/reopen'

end
