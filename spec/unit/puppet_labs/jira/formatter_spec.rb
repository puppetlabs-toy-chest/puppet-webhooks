require 'spec_helper'
require 'puppet_labs/jira/formatter'

describe PuppetLabs::Jira::Formatter do

  let(:payload) { read_fixture("example_pull_request.json") }
  let(:pull_request) { PuppetLabs::Github::PullRequest.new(:json => payload) }

  let(:github_account) do
    {
      'name' => 'Github user',
      'email' => 'user@fqdn.blackhole',
      'company' => 'Company Inc.',
      'html_url' => 'fqdn.blackhole',
    }
  end

  before :each do
    github_api = double('github api', :account => github_account)
    pull_request.stub(:github).and_return github_api
  end

  describe 'formatting the description' do
    subject { described_class.format_pull_request(pull_request)[:description] }

    it "contains the author name" do
      subject.should match pull_request.author_name
    end

    it "contains the author Github ID" do
      subject.should match pull_request.author
    end

    it "contains the pull request number" do
      subject.should match pull_request.number.to_s
    end

    it "contains a link to the discussion" do
      subject.should match pull_request.html_url
    end

    it "contains a link to the file diff" do
      subject.should match "#{pull_request.html_url}/files"
    end

    it "contains the body of the pull request message" do
      subject.should match pull_request.body
    end
  end

  describe 'formatting the summary' do
    subject { described_class.format_pull_request(pull_request)[:summary] }

    it "contains the pull request number" do
      subject.should match pull_request.number.to_s
    end

    it "contains the pull request title" do
      subject.should match pull_request.title
    end
  end
end

