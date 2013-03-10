require 'json'
require 'puppet_labs/issue'

# This class provides a model of a GitHub comment.
module PuppetLabs
class Comment
  # Comment data
  attr_reader :body,
    :issue,
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
  end
end
end
