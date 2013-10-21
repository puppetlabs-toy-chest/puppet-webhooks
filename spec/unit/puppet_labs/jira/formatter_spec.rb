require 'spec_helper'
require 'puppet_labs/jira/formatter'

describe PuppetLabs::Jira::Formatter do

  include_context "Github pull request fixture"

  describe 'formatting the description' do
    subject { described_class.format_pull_request(pr)[:description] }

    it "contains the author name" do
      subject.should match pr.author_name
    end

    it "contains the author Github ID" do
      subject.should match pr.author
    end

    it "contains the pull request number" do
      subject.should match pr.number.to_s
    end

    it "contains a link to the discussion" do
      subject.should match pr.html_url
    end

    it "contains a link to the file diff" do
      subject.should match "#{pr.html_url}/files"
    end

    it "contains the body of the pull request message" do
      subject.should match pr.body
    end

    it "contains a webhooks identifier field" do
      subject.should match /\(webhooks-id: [\da-zA-Z]+\)/
    end
  end

  describe 'formatting the summary' do
    subject { described_class.format_pull_request(pr)[:summary] }

    it "contains the pull request number" do
      subject.should match pr.number.to_s
    end

    it "contains the pull request title" do
      subject.should match pr.title
    end
  end
end

