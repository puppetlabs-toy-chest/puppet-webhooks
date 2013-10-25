require 'puppet_labs/jira/event/pull_request'

require 'puppet_labs/jira/issue_matcher'
require 'puppet_labs/jira/client'

class PuppetLabs::Jira::Event::PullRequest::Base

  include PuppetLabs::Jira::Client
  include PuppetLabs::Jira::IssueMatcher

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

  # @!attribute [rw] project
  #   @return [PuppetLabs::Project]
  attr_accessor :project

  # @!attribute [rw] pull_request
  #   @return [PuppetLabs::Github::PullRequest]
  attr_accessor :pull_request

  attr_writer :logger

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end

end
