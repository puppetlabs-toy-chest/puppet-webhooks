require 'puppet_labs/github/pull_request'
require 'puppet_labs/github/event_base'

module PuppetLabs
module Github

# This class provides a model of a github issue.
#
# @see http://developer.github.com/v3/issues/
class Issue < PuppetLabs::Github::EventBase

  # @!attribute [r] number
  #   @return [Numeric] The github issue number
  attr_reader :number

  # @!attribute [r] title
  #   @return [String] The title field of the github issue
  attr_reader :title

  # @!attribute [r] html_url
  #   @return [String] The URL to the github issue
  attr_reader :html_url

  # @!attribute [r] pull_request
  #   @return [PuppetLabs::Github::PullRequest] The pull request associated
  #     with this issue if one is present.
  attr_reader :pull_request

  def load_json(json)
    super

    @number = @raw['issue']['number']
    @title = @raw['issue']['title']
    @html_url = @raw['issue']['html_url']
    @body = @raw['issue']['body']
    @repo_name = @raw['repository']['name']
    @pull_request = ::PuppetLabs::Github::PullRequest.from_json(JSON.dump({
      'pull_request' => @raw['issue']['pull_request'],
      'repository' => @raw['repository']
    }))
  end

  def event_description
    "(issue) #{repo_name} #{number}"
  end
end
end
end
