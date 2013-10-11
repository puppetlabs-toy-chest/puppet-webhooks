require 'spec_helper'
require 'puppet_labs/jira/pull_request_handler'

describe PuppetLabs::Jira::PullRequestHandler do
  let(:payload) { read_fixture("example_pull_request.json") }
  let (:pr) { PuppetLabs::Github::PullRequest.new(:json => payload) }

  let(:jira_api) { double('JIRA::Client') }

  before :each do
    # Stub logging
    subject.stub(:logger).and_return(double.as_null_object)

    # And the JIRA API
    subject.api = jira_api
    subject.pull_request = pr
    subject.stub(:project).and_return 'TEST'

    # And the Github API
    github_account = {
      'name' => 'Github user',
      'email' => 'user@fqdn.blackhole',
      'company' => 'Company Inc.',
      'html_url' => 'fqdn.blackhole',
    }

    github_api = double('PuppetLabs::Github::GithubAPI', :account => github_account)
    pr.stub(:github).and_return github_api
  end

  describe "when a pull request is opened" do
    describe "and there is no existing Jira issue" do
      let(:jira_issue) { double('PuppetLabs::Jira::Issue') }

      before do
        jira_api.stub_chain(:Issue, :build)
        allow(PuppetLabs::Jira::Issue).to receive(:new).and_return jira_issue
      end

      it "creates a new jira issue" do
        allow(jira_issue).to receive(:remotelink)
        expect(jira_issue).to receive(:create).with('TEST', pr.summary, pr.description, 'Task')

        subject.perform
      end

      it "adds a link to the new issue referencing the pull request" do
        allow(jira_issue).to receive(:create)
        expect(jira_issue).to receive(:remotelink).with(pr.html_url, "Github Pull Request: #{pr.title}", anything)

        subject.perform
      end
    end

    describe "and there is an existing Jira issue" do
      let(:jira_issue) { double('PuppetLabs::Jira::Issue') }

      before :each do
        allow(pr).to receive(:title).and_return '[TEST-123] Pull request titles should reference a jira key'
        allow(PuppetLabs::Jira::Issue).to receive(:new).and_return jira_issue
      end

      let(:found_issue) { double('JIRA::Resource::Issue', :key => 'TEST-123') }

      it "doesn't create a new pull request" do
        expect(JIRA::Resource::Issue).to receive(:find).with(jira_api, 'TEST-123').and_return found_issue

        expect(jira_issue).to receive(:create).never
        allow(jira_issue).to receive(:remotelink)

        subject.perform
      end

      it "adds the pull request as a new remote link" do
        expect(JIRA::Resource::Issue).to receive(:find).with(jira_api, 'TEST-123').and_return found_issue

        expect(jira_issue).to receive(:remotelink).once

        subject.perform
      end

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
