require 'spec_helper'
require 'puppet_labs/pull_request_job'

describe PuppetLabs::PullRequestJob do
  let(:payload) { read_fixture("example_pull_request.json") }
  let (:pr) { PuppetLabs::PullRequest.new(:json => payload) }

  let :expected_pr_body do
    [ "Links: [Pull Request #{pr.number} Discussion](#{pr.html_url}) and",
      "[File Diff](#{pr.html_url}/files)",
      '',
      pr.body,
    ].join("\n")
  end

  let :expected_card_title do
    "(PR #{pr.repo_name}/#{pr.number}) #{pr.title}"
  end

  subject do
    job = PuppetLabs::PullRequestJob.new
    job.pull_request = PuppetLabs::PullRequest.new(:json => payload)
    job
  end

  before :each do
    subject.stub(:display_card)
  end

  it 'stores a pull request' do
    subject.pull_request = pr
    subject.pull_request.should be pr
  end

  it 'produces a card body' do
    subject.card_body.should be_a String
  end

  it 'produces a well formatted card body' do
    subject.card_body.should == expected_pr_body
  end

  it 'produces a well formatted card title' do
    subject.card_title.should == expected_card_title
  end

  it 'queues the job' do
    subject.should_receive(:queue_job).with(subject, :queue => 'pull_request')
    subject.queue
  end

  it 'performs the job' do
    subject.perform
  end
end
