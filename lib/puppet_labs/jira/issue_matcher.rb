require 'puppet_labs/jira'

module PuppetLabs::Jira::IssueMatcher

  # Search for a Jira issue associated with a github event
  #
  # Issues referenced in the title have priority over issues with an ID so that
  # working with existing issues takes priority over creating a new issue. This
  # is mainly significant for commenting on existing Jira issues with a linked
  # Github event.
  #
  # @param title [String] The event title
  # @param id [String] The webhook id for the event
  #
  # @return [PuppetLabs::Jira::Issue]
  def issue_for_event(title, id)
    @jira_issue ||= (issue_by_title(title) || issue_by_id(id))
  end

  # Look up a Jira issue containing a string unique to this event
  #
  # @return [PuppetLabs::Jira::Issue]
  def issue_by_id(id)
    PuppetLabs::Jira::Issue.matching_webhook_id(client, project, id)
  end

  # Try to look up a Jira issue based on the first matching Jira issue in the
  # github pull request title.
  #
  # @example
  #   pull_request.title
  #   #=> "[WH-123] pull requests should be linked to existing tickets
  #   event_handler.issue_by_title
  #   #=> #<PuppetLabs::Jira::Issue:0xdeadbeef key='WH-123'>
  #
  def issue_by_title(title)
    pattern = %r[\b#{project.jira_project}-(?:\d+)\b]

    key = title.scan(pattern).first

    if key
      PuppetLabs::Jira::Issue.find(client, project, key).first
    end
  end
end
