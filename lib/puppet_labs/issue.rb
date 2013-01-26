require 'json'

# This class provides a model of a github issue.
module PuppetLabs
class Issue
  # Pull request data
  attr_reader :number,
    :repo_name,
    :title,
    :html_url,
    :body,
    :action

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
    @number = data['issue']['number']
    @title = data['issue']['title']
    @html_url = data['issue']['html_url']
    @body = data['issue']['body']
    @repo_name = data['repository']['name']
    @action = data['action']
  end
end
end
