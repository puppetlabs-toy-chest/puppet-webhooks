require 'spec_helper'
require 'puppet_labs/jira/event/pull_request/open'

describe PuppetLabs::Jira::Event::PullRequest::Open do

  let (:pull_request) do
    PuppetLabs::Github::PullRequest.new(:json => read_fixture("example_pull_request.json"))
  end

  let(:jira_client) { double('JIRA::Client') }
  let(:project)  { 'TEST' }

  subject { described_class.new(project, pull_request, jira_client) }

  before :each do
    # Stub logging
    subject.logger = double.as_null_object

    # And the Github API
    github_account = {
      'name' => 'Github user',
      'email' => 'user@fqdn.blackhole',
      'company' => 'Company Inc.',
      'html_url' => 'fqdn.blackhole',
    }

    github_client = double('PuppetLabs::Github::GithubAPI', :account => github_account)
    pull_request.stub(:github).and_return github_client
  end

  describe "and there is no existing pull request" do
    let(:jira_issue) { double('PuppetLabs::Jira::Issue', :key => "#{project}-314") }

    before do
      allow(PuppetLabs::Jira::Issue).to receive(:build).and_return jira_issue
    end

    it "creates a new jira issue" do
      allow(jira_issue).to receive(:remotelink)
      expect(jira_issue).to receive(:create) do |*args|
        expect(args[0]).to eq project
        expect(args[1]).to be_a_kind_of String
        expect(args[2]).to be_a_kind_of String
        expect(args[3]).to eq 'Task'
      end

      subject.perform
    end

    it "adds a link to the new issue referencing the pull request" do
      allow(jira_issue).to receive(:create)
      expect(jira_issue).to receive(:remotelink).with(pull_request.html_url, "Pull Request: #{pull_request.title}", 'Github', anything)

      subject.perform
    end
  end

  describe "and there is an existing pull request" do
    let(:jira_issue) { double('PuppetLabs::Jira::Issue', :key => "#{project}-314") }

    before :each do
      allow(pull_request).to receive(:title).and_return "[#{project}-123] Pull request titles should reference a jira key"
      allow(PuppetLabs::Jira::Issue).to receive(:new).and_return jira_issue
    end

    let(:found_issue) { double('JIRA::Resource::Issue', :key => "#{project}-123") }

    it "doesn't create a new pull request" do
      expect(JIRA::Resource::Issue).to receive(:find).with(jira_client, 'TEST-123').and_return found_issue

      expect(jira_issue).to receive(:create).never
      allow(jira_issue).to receive(:remotelink)

      subject.perform
    end

    it "adds the pull request as a new remote link" do
      expect(JIRA::Resource::Issue).to receive(:find).with(jira_client, 'TEST-123').and_return found_issue

      expect(jira_issue).to receive(:remotelink).once

      subject.perform
    end

    it "adds a comment on the issue referencing the pull request"
  end
end
