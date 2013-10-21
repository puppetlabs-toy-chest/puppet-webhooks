require 'puppet_labs/github/issue'
require 'puppet_labs/github/event_base'

module PuppetLabs
module Github

# This class provides a model of a GitHub comment. Comments on both Github
# issues and events are handled as this class.
#
# @see http://developer.github.com/v3/issues/comments/
# @see http://developer.github.com/guides/working-with-comments/
class Comment < PuppetLabs::Github::EventBase
  # Comment data
  attr_reader :issue,
    :pull_request

  # @!attribute [r] user
  #   @return [PuppetLabs::Github::User] The user that created this comment
  attr_reader :user

  def load_json(json)
    super

    @body = @raw['comment']['body']
    @issue = ::PuppetLabs::Github::Issue.from_json(json)
    @pull_request = @issue.pull_request
    @repo_name = @issue.repo_name
    @full_name = @issue.full_name

    @user = PuppetLabs::Github::User.from_hash(@raw['sender'])
  end

  # This determines whether the comment was on a Pull Request or Issue
  #
  # @returns [Boolean] true/false
  def pull_request?
    !!issue.pull_request.html_url
  end

  def event_description
    "(comment) #{repo_name} #{issue.number}"
  end

  def author_login
    user.login
  end

  def author_avatar_url
    user.avatar_url
  end
end
end
end
