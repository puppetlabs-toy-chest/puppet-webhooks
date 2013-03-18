require 'puppet_labs/controller'
require 'puppet_labs/pull_request_controller'
require 'puppet_labs/issue_controller'
require 'puppet_labs/comment_controller'

module PuppetLabs
class GithubController < Controller
  ##
  # event_controller returns an instance of a controller class suitable for running.
  # If no controller is registered for the Github event then `nil` is returned.
  #
  # This method maps the X-Github-Event HTTP header onto a subclass of the
  # PuppetLabs::Controller base class.
  #
  # @return [PuppetLabs::Controller] subclass instance suitable to send the run
  # message to, or `nil`.
  def event_controller
    case gh_event = request.env['HTTP_X_GITHUB_EVENT'].to_s
    when 'pull_request'
      logger.info "Handling X-Github-Event (pull_request): #{gh_event}"
      pull_request = PuppetLabs::PullRequest.from_json(route.payload)
      options = @options.merge({
        :pull_request => pull_request
      })
      controller = PuppetLabs::PullRequestController.new(options)
      return controller
    when 'issues'
      logger.info "Handling X-Github-Event (issues): #{gh_event}"
      issue = PuppetLabs::Issue.from_json(route.payload)
      options = @options.merge({
        :issue => issue
      })
      controller = PuppetLabs::IssueController.new(options)
      return controller
    when 'issue_comment'
      logger.info "Handling X-Github-Event (issues): #{gh_event}"
      comment = PuppetLabs::Comment.from_json(route.payload)
      options = @options.merge({
        :comment => comment
      })
      controller = PuppetLabs::CommentController.new(options)
      return controller
    else
      logger.info "Ignoring X-Github-Event: #{gh_event}"
      return nil
    end
  end
end
end
