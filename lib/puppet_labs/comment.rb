require 'json'
require 'puppet_labs/issue'

# This class provides a model of a GitHub comment.
module PuppetLabs
class Comment
  # Comment data
  attr_reader :body,
    :issue,
    :pull_request,
    :repo_name,
    :action

  def self.from_json(json)
    new(:json => json)
  end

  def initialize(options = {})
    options[:json] && load_json(options[:json])
  end

  def load_json(json)
    data = JSON.load(json)
    @body = data['comment']['body']
    @action = data['action']
    @issue = ::PuppetLabs::Issue.from_json(json)
    @pull_request = @issue.pull_request
    @repo_name = @issue.repo_name
  end
end
end
