require 'spec_helper'
require 'puppet_labs/jira/event/pull_request/close'

describe PuppetLabs::Jira::Event::PullRequest::Close do

  include_context "Github pull request fixture"

  let(:jira_client) { double('JIRA::Client') }
  let(:project)  { 'TEST' }

  subject { described_class.new(pr, project, jira_client) }

  before :each do
    subject.logger = double.as_null_object
  end

  let(:jira_issue) { double('PuppetLabs::Jira::Issue', :key => "#{project}-314") }

  it "adds a comment on the issue associated with the pull request" do
    expect(PuppetLabs::Jira::Issue).to receive(:matching_webhook_id).with(
      jira_client, an_instance_of(String)
    ).and_return(jira_issue)

    expect(jira_issue).to receive(:comment) do |str|
      expect(str).to match /Pull request.*closed/
    end

    subject.perform
  end

end
