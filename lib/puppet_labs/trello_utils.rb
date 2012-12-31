require 'erb'
require 'puppet_labs/trello/card'
require 'puppet_labs/pull_request_job'
require 'active_record'


module PuppetLabs
module TrelloUtils
  ##
  # queue_pull_request creates a Delayed Job to handle the data related to an
  # event on a github pull request.
  def queue_pull_request
    job = PullRequestJob.new
  end
end
end
