require 'spec_helper'
require 'puppet_labs/jira/event/pull_request/open'

describe PuppetLabs::Jira::Event::PullRequest::Open do

  include_context "Github pull request fixture"

  let(:jira_client) { double('JIRA::Client') }
  let(:project)     { 'TEST' }
  let(:jira_issue)  { double('PuppetLabs::Jira::Issue', :key => "#{project}-314") }

  subject { described_class.new(pr, project, jira_client) }

  before :each do
    subject.logger = double.as_null_object

    allow(jira_issue).to receive(:project=)
    allow(jira_issue).to receive(:issuetype=)
  end

  describe "and there is no existing pull request" do

    before do
      allow(PuppetLabs::Jira::Issue).to receive(:build).and_return jira_issue
      allow(subject).to receive(:issue_by_title).and_return nil
      allow(subject).to receive(:issue_by_id).and_return nil
    end

    it "creates a new jira issue" do
      allow(jira_issue).to receive(:remotelink)
      expect(jira_issue).to receive(:create) do |*args|
        expect(args[0]).to be_a_kind_of String
        expect(args[1]).to be_a_kind_of String
      end

      subject.perform
    end

    it "adds a link to the new issue referencing the pull request" do
      allow(jira_issue).to receive(:create)
      expect(jira_issue).to receive(:remotelink).with(pr.html_url, "Pull Request: #{pr.title}", 'Github', anything)

      subject.perform
    end
  end

  describe "and the pull request references a Jira issue" do

    before :each do
      allow(subject).to receive(:issue_by_id)
    end

    it "doesn't create a new pull request" do
      allow(subject).to receive(:issue_by_title).and_return jira_issue

      expect(jira_issue).to receive(:create).never
      allow(jira_issue).to receive(:remotelink)

      subject.perform
    end

    it "adds the pull request as a new remote link" do
      allow(subject).to receive(:issue_by_title).and_return jira_issue

      expect(jira_issue).to receive(:remotelink).once

      subject.perform
    end

    it "adds a comment on the issue referencing the pull request"
  end

  describe "and the pull request already has a linked issue" do
    before do
      allow(subject).to receive(:issue_by_id).and_return jira_issue
    end

    it "doesn't create a new pull request" do
      expect(jira_issue).to receive(:create_issue).never
      subject.perform
    end

    it "doesn't create a new issue link" do
      expect(jira_issue).to receive(:link_issue).never
      subject.perform
    end
  end
end
