require 'puppet_labs/jira/event/pull_request'

require 'puppet_labs/jira/client'

class PuppetLabs::Jira::Event::PullRequest::Base
  include PuppetLabs::Jira::Client

  def self.perform(pull_request, project, client = nil)
    obj = new(pull_request, project, client)
    obj.perform
    obj
  end

  def initialize(pull_request, project, client = nil)
    @pull_request = pull_request
    @project      = project
    @client       = client
  end

  attr_accessor :project
  attr_accessor :pull_request

  attr_writer :logger

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
