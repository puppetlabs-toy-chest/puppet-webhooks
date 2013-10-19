module PuppetLabs
  module Github
    require 'puppet_labs/github/client'

    require 'puppet_labs/github/event_base'
    require 'puppet_labs/github/comment'
    require 'puppet_labs/github/issue'
    require 'puppet_labs/github/pull_request'
    require 'puppet_labs/github/user'

    require 'puppet_labs/github/controller'
    require 'puppet_labs/github/comment_controller'
    require 'puppet_labs/github/github_controller'
    require 'puppet_labs/github/issue_controller'
    require 'puppet_labs/github/pull_request_controller'
  end
end
