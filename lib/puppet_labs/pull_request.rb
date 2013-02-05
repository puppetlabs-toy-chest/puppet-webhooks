require 'json'

# This class provides a model of a pull rquest.
module PuppetLabs
class PullRequest
  # Pull request data
  attr_reader :number,
    :repo_name,
    :title,
    :html_url,
    :body,
    :action,
    :message

  def self.from_json(json)
    new(:json => json)
  end

  def initialize(options = {})
    if json = options[:json]
      load_json(json)
    end
  end

  def load_json(json)
    data = JSON.load(json)
    @message = data
    @number = data['pull_request']['number']
    @title = data['pull_request']['title']
    @html_url = data['pull_request']['html_url']
    @body = data['pull_request']['body']
    @repo_name = data['repository']['name']
    @action = data['action']
  end
end
end
