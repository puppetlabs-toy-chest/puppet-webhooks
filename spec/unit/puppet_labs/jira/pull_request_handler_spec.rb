require 'spec_helper'
require 'puppet_labs/jira/pull_request_handler'

describe PuppetLabs::Jira::PullRequestHandler do
  let(:payload) { read_fixture("example_pull_request.json") }
  let (:pr) { PuppetLabs::Github::PullRequest.new(:json => payload) }

  let(:jira_client) { double('JIRA::Client') }

  before :each do
    # Stub logging
    subject.stub(:logger).and_return(double.as_null_object)

    # And the JIRA API
    subject.client = jira_client
    subject.pull_request = pr
    subject.stub(:project).and_return 'TEST'

    # And the Github API
    github_account = {
      'name' => 'Github user',
      'email' => 'user@fqdn.blackhole',
      'company' => 'Company Inc.',
      'html_url' => 'fqdn.blackhole',
    }

    github_client = double('PuppetLabs::Github::GithubAPI', :account => github_account)
    pr.stub(:github).and_return github_client
  end

  describe "when a pull request is closed" do
    it "adds a comment on the issue indicating the issue was closed"
  end

  describe "when a pull request is reopened" do
    it "adds a comment on the issue indicating the issue was reopened"
  end

  describe "with an unhandled pull request action" do
    it "logs a warning"
  end
end
