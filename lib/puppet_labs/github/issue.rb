require 'json'
require 'puppet_labs/github/pull_request'
require 'puppet_labs/github/event_base'

module PuppetLabs
module Github

# This class provides a model of a github issue.
#
# @see http://developer.github.com/v3/issues/
class Issue < PuppetLabs::Github::EventBase

  # Issue data
  attr_reader :number,
    :title,
    :html_url,
    :pull_request

  def load_json(json)
    data = JSON.load(json)
    @number = data['issue']['number']
    @title = data['issue']['title']
    @html_url = data['issue']['html_url']
    @body = data['issue']['body']
    @repo_name = data['repository']['name']
    @action = data['action']
    @pull_request = ::PuppetLabs::Github::PullRequest.from_json(JSON.dump({
      'pull_request' => data['issue']['pull_request'],
      'repository' => data['repository']
    }))
  end

  def event_description
    "(issue) #{repo_name} #{number}"
  end
end
end
end
