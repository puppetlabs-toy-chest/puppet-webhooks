require 'json'
require 'puppet_labs/github_mix'
require 'puppet_labs/cla_mix'

# This class provides a model of a pull rquest.
module PuppetLabs
class PullRequest
  include GithubMix
  include ClaMix

  # Pull request data
  attr_reader :number,
    :env,
    :repo_name,
    :title,
    :html_url,
    :body,
    :action,
    :message,
    :created_at,
    :author,
    :author_avatar_url

  def self.from_json(json)
    new(:json => json)
  end

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
    load_data(JSON.load(json))
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
end
end
