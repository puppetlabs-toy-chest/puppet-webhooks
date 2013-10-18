require 'puppet_labs/github/event_base'
require 'puppet_labs/github/github_mix'

module PuppetLabs
module Github

# This class provides a model of a pull rquest.
#
# @see http://developer.github.com/v3/pulls/
class PullRequest < PuppetLabs::Github::EventBase
  include GithubMix
  # Pull request data
  attr_reader :number,
    :env,
    :title,
    :html_url,
    :message,
    :created_at,
    :author,
    :author_avatar_url

  def self.from_data(data)
    new(:data => data)
  end

  def initialize(options = {})
    if json = options[:json]
      load_json(json)
    elsif data = options[:data]
      load_data(data)
    end
    if env = options[:env]
      @env = env
    else
      @env = ENV.to_hash
    end
  end

  def load_json(json)
    super

    load_data(@raw)
  end

  def load_data(data)

    @message = data
    pr = data['pull_request'] || data
    @number = pr['number']
    @title = pr['title']
    @html_url = pr['html_url']
    @body = pr['body']
    repo = data['repository'] || data['base']['repo']
    @repo_name = repo['name']
    @action = data['action']
    @action = 'opened' if action.nil? && data['state'] == 'open'
    @created_at = pr['created_at']
    sender = data['sender'] || data['user']
    if sender
      @author = sender['login']
      @author_avatar_url = sender['avatar_url']
    end
  end

  def event_description
    "(pull request) #{repo_name} #{number}"
  end
end
end
end
