require 'spec_helper'
require 'puppet_labs/jira/event/pull_request/close'

describe PuppetLabs::Jira::Event::PullRequest::Close do

  let (:pull_request) do
    PuppetLabs::Github::PullRequest.new(:json => read_fixture("example_pull_request.json"))
  end

  let(:jira_client) { double('JIRA::Client') }
  let(:project)  { 'TEST' }

  subject { described_class.new(project, pull_request, jira_client) }

  before :each do
    # Stub logging
    subject.stub(:logger).and_return(double.as_null_object)

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

  let(:jira_issue) { double('PuppetLabs::Jira::Issue', :key => "#{project}-314") }

  it "adds a comment on the issue associated with the pull request" do
    expect(PuppetLabs::Jira::Issue).to receive(:matching_summary).with(
      jira_client, an_instance_of(String)
    ).and_return([jira_issue])

    expect(jira_issue).to receive(:comment) do |str|
      expect(str).to match /Pull request.*closed/
    end

    subject.perform
  end

end
