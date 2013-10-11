require 'spec_helper'
require 'puppet_labs/jira/pull_request_handler'

describe PuppetLabs::Jira::PullRequestHandler do
  let(:payload) { read_fixture("example_pull_request.json") }
  let (:pr) { PuppetLabs::Github::PullRequest.new(:json => payload) }

  let(:api) { double 'jira api' }

  before :each do
    # Stub logging
    subject.stub(:logger).and_return(double.as_null_object)

    # And the JIRA API
    subject.api = api
    subject.pull_request = pr
    subject.stub(:project).and_return 'testing'

    # And the Github API
    github_account = {
      'name' => 'Github user',
      'email' => 'user@fqdn.blackhole',
      'company' => 'Company Inc.',
      'html_url' => 'fqdn.blackhole',
    }

    github_api = double('github api', :account => github_account)
    pr.stub(:github).and_return github_api
  end

  describe "when a pull request is opened" do
    describe "and there is no existing Jira issue" do

      it "creates a new jira issue" do
        issue = double('jira issue')
        api.stub_chain(:Issue, :build).and_return issue

        expect(issue).to receive(:save) do |message|
          expect(message['fields']['summary']).to eq pr.summary
          expect(message['fields']['description']).to eq pr.description
          expect(message['fields']['project']).to eq({'key' => 'testing'})
          expect(message['fields']['issuetype']).to eq({'name' => 'Task'})
        end

        subject.perform
      end
    end

    describe "and there is an existing Jira issue" do
      it "adds the pull request as a new remote link"
      it "adds a comment on the issue referencing the pull request"
    end
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
