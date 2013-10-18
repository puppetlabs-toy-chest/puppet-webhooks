require 'spec_helper'
require 'puppet_labs/jira/event/pull_request/open'

describe PuppetLabs::Jira::Event::PullRequest::Open do

  include_context "Github pull request fixture"

  let(:jira_client) { double('JIRA::Client') }
  let(:project)  { 'TEST' }

  subject { described_class.new(pr, project, jira_client) }

  before :each do
    subject.logger = double.as_null_object
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
      expect(jira_issue).to receive(:remotelink).with(pr.html_url, "Pull Request: #{pr.title}", 'Github', anything)

      subject.perform
    end
  end

  describe "and there is an existing pull request" do
    let(:jira_issue) { double('PuppetLabs::Jira::Issue', :key => "#{project}-314") }

    before :each do
      allow(pr).to receive(:title).and_return "[#{project}-123] Pull request titles should reference a jira key"
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
